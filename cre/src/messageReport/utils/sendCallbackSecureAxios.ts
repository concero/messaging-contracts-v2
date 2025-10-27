import {
  cre,
  ok,
  consensusIdenticalAggregation,
  type Runtime,
  type NodeRuntime,
  type Report,
} from "@chainlink/cre-sdk";
import { randomBytes, createHash, createHmac } from "node:crypto";
import { keccak256 } from "viem";

export type CallbackCfg = {
  url: string;
  keyId?: string;
  secretEnv?: string;
  sharedSecretFallback?: string;
  timeoutMs?: number;
  retries?: number;
  pinCertSha256B64?: string;
  maxBodyBytes?: number;
  maxSkewSec?: number;
};

export type CallbackResult = { ok: true };

export function sendReportSecureAxios(
  runtime: Runtime<any>,
  report: Report,
  cfg: CallbackCfg,
): CallbackResult {
  if (!cfg.url || !cfg.url.startsWith("https://")) {
    throw new Error("Callback URL must be HTTPS");
  }

  const nodeFn = async (nodeRuntime: NodeRuntime<any>): Promise<CallbackResult> => {
    const axios = (await import("axios")).default;
    const https = await import("node:https");
    const tls = await import("node:tls");

    const context: any =
      (report as any).context ??
      (report as any).reportContext ??
      null;
    if (!context) {
      throw new Error("Report missing context/reportContext");
    }

    const signatures = (report as any).sigs?.map((s: any) => ({
      signerId: s.signerId?.toString?.() ?? String(s.signerId),
      signatureB64: Buffer.from(s.signature).toString("base64"),
    })) ?? [];

    const payload = {
      seqNr: report.x_generatedCodeOnly_unwrap().seqNr,
      reportB64: Buffer.from(report.x_generatedCodeOnly_unwrap().rawReport).toString("base64"),
      context,
      signatures,
    };

    const body = Buffer.from(JSON.stringify(payload), "utf8");

    const ts = Math.floor(Date.now() / 1000).toString();
    const nonce = randomBytes(16).toString("hex");
    const bodySha256 = createHash("sha256").update(body).digest("hex");
    const secret =
      process.env[cfg.secretEnv ?? "CRE_CALLBACK_SECRET"] ??
      cfg.sharedSecretFallback ??
      "";
    if (!secret) {
      throw new Error("Missing shared secret (env or fallback)");
    }

    const signingString = `ts=${ts}\nnonce=${nonce}\nbodyHash=${bodySha256}\nurl=${cfg.url}`;
    const sigHex = createHmac("sha256", Buffer.from(secret, "utf8"))
      .update(signingString)
      .digest("hex");

    const idempotencyKey = keccak256(new Uint8Array(report.x_generatedCodeOnly_unwrap().rawReport as any));

    const agentOpts = {
      keepAlive: true,
      rejectUnauthorized: true,
      ...(cfg.pinCertSha256B64
        ? {
            checkServerIdentity: (_host, cert) => {
              const actual = createHash("sha256").update(cert.raw).digest("base64");
              if (actual !== cfg.pinCertSha256B64) {
                const err = new Error("TLS certificate pin mismatch");
                (err as any).code = "EPIN";
                throw err;
              }
              return undefined;
            },
          }
        : {}),
    };
    const httpsAgent = new https.Agent(agentOpts);

    const timeoutMs = cfg.timeoutMs ?? 10_000;
    const retries = Math.max(0, cfg.retries ?? 2);
    const maxBodyBytes = cfg.maxBodyBytes ?? 2 * 1024 * 1024;

    const headers = {
      "Content-Type": "application/json",
      "Content-Length": String(body.length),
      "X-Key-Id": cfg.keyId ?? "default",
      "X-Timestamp": ts,
      "X-Nonce": nonce,
      "X-Content-SHA256": bodySha256,
      "X-Auth-Signature": `v1=${sigHex}`,
      "X-Report-SeqNr": String(report.x_generatedCodeOnly_unwrap().seqNr),
      "Idempotency-Key": idempotencyKey,
    } as const;

    let lastErr: unknown;
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        const res = await axios.post(cfg.url, body, {
          headers,
          httpsAgent,
          timeout: timeoutMs,
          maxRedirects: 0,
          maxBodyLength: maxBodyBytes,
          validateStatus: (s) => s >= 200 && s < 300,
        });
        if (!ok({ statusCode: res.status })) {
          throw new Error(`HTTP ${res.status}`);
        }
        return { ok: true };
      } catch (e) {
        lastErr = e;
        if (attempt === retries) break;
        const backoff = Math.min(1500 * 2 ** attempt, 8000);
        const jitter = Math.floor(Math.random() * 200);
        await new Promise((r) => setTimeout(r, backoff + jitter));
      }
    }

    throw lastErr instanceof Error ? lastErr : new Error(String(lastErr));
  };

  runtime
    .runInNodeMode(nodeFn, consensusIdenticalAggregation<CallbackResult>())
    ()
    .result();

  return { ok: true };
}
