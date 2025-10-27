import {
  cre,
  ok,
  consensusIdenticalAggregation,
  type Runtime,
  type NodeRuntime,
  type Report,
} from "@chainlink/cre-sdk";
import { createHmac, randomBytes } from "node:crypto";
import { keccak256, sha256 } from "viem";

export type CallbackCfg = {
  url: string;
  keyId?: string;
  secretId?: string;
  maxAgeMs?: number;
};

export type CallbackResult = { ok: true };

export function sendReportSecure(
  runtime: Runtime<any>,
  report: Report,
  cfg: CallbackCfg,
): CallbackResult {
  const http = new cre.capabilities.HTTPClient();

  const nodeFn = (nodeRuntime: NodeRuntime<any>): CallbackResult => {
    const secretId = cfg.secretId ?? "CALLBACK_SIGNING_KEY";

    const formatReportSecure = (r: any): any => {
      const nonce = randomBytes(16).toString("hex");
      const timestamp = Math.floor(Date.now() / 1000).toString();

      const bodyB64 = Buffer.from(r.rawReport).toString("base64");

      const reportHash = keccak256(r.rawReport);
      const bodySha256 = sha256(r.rawReport);

      const signingString = `ts=${timestamp}\nnonce=${nonce}\nbodyHash=${bodySha256}\nurl=${cfg.url}`;
      const sigHex = createHmac("sha256", Buffer.from(secretId, "utf8"))
        .update(signingString)
        .digest("hex");

      const headers: Record<string, string> = {
        "Content-Type": "application/octet-stream",
        "X-Report-SeqNr": r.seqNr.toString(),
        "X-Report-Hash": reportHash,
        "X-Key-Id": cfg.keyId ?? "default",
        "X-Timestamp": timestamp,
        "X-Nonce": nonce,
        "X-Content-SHA256": bodySha256,
        "X-Auth-Signature": `v1=${sigHex}`,
        "Idempotency-Key": reportHash,
      };

      r.sigs.forEach((sig: { signature: any; signerId: { toString: () => string; }; }, i: any) => {
        headers[`X-Signature-${i}`] = Buffer.from(sig.signature).toString("base64");
        headers[`X-Signer-ID-${i}`] = sig.signerId.toString();
      });

      return {
        url: cfg.url,
        method: "POST",
        body: bodyB64,
        headers,
        cacheSettings: { readFromCache: true, maxAgeMs: cfg.maxAgeMs ?? 60_000 },
      };
    };

    const res = http.sendReport(nodeRuntime, report, formatReportSecure).result();
    if (!ok(res)) throw new Error(`Callback HTTP error: ${res.statusCode}`);

    return { ok: true };
  };

  runtime.runInNodeMode(nodeFn, consensusIdenticalAggregation<CallbackResult>())().result();
  return { ok: true };
}
