// message-report/main.ts
import {
  cre,
  Runner,
  hexToBase64,
  type Runtime,
  consensusIdenticalAggregation,
  type Report,
  NodeRuntime,
} from "@chainlink/cre-sdk";

import { keccak256 } from "viem"
import { main as buildPacked } from "../../../messageReport/messageReport";
import { sendReportSecureAxios } from "../../../messageReport/utils/sendCallbackSecureAxios";

type Payload = {
  txHash?: `0x${string}`;
  eventIndex?: number;
  bytesArgs?: `0x${string}`;
  rpcUrl?: string;
  contractAddress?: `0x${string}`;
  eventSignature?: string;
  callbackUrl?: string;
  callbackKeyId?: string;
  callbackSecret?: string;
};

type Config = {};

function pickBytesArgsFromReceipt(
  receipt: any,
  p: Payload,
  runtime: Runtime<Config>
): `0x${string}` | undefined {
  if (!receipt?.logs?.length) return undefined;

  if (typeof p.eventIndex === "number") {
    const log = receipt.logs[p.eventIndex];
    return log?.data as `0x${string}` | undefined;
  }

  let logs: any[] = receipt.logs;
  if (p.contractAddress) {
    logs = logs.filter((l) => l.address?.toLowerCase() === p.contractAddress!.toLowerCase());
  }
  if (p.eventSignature) {
    const topic0 = keccak256(new TextEncoder().encode(p.eventSignature)); // topic0 = keccak256(sig)
    logs = logs.filter((l) => Array.isArray(l.topics) && l.topics[0]?.toLowerCase() === topic0.toLowerCase());
  }

  const first = logs[0];
  if (!first?.data) {
    runtime.log("⚠️ No log with data data — check eventIndex/contractAddress/eventSignature");
    return undefined;
  }
  return first.data as `0x${string}`;
}

async function fetchTxReceipt(runtime: Runtime<Config>, rpcUrl: string, txHash: string) {
  const http = new cre.capabilities.HTTPClient();
  const req = {
    url: rpcUrl,
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "eth_getTransactionReceipt",
      params: [txHash],
    }),
    cacheSettings: { readFromCache: false, maxAgeMs: 0 },
  };

  const res = http.sendRequest(runtime as unknown as NodeRuntime<Config>, req).result();
  if (res.statusCode !== 200) {
    throw new Error(`RPC ${rpcUrl} returned ${res.statusCode}`);
  }

  const text = new TextDecoder().decode(res.body);
  const json = text ? JSON.parse(text) : null;
  if (!json?.result) throw new Error(`No receipt result for ${txHash}`);
  return json.result;
}

const onHttp = async (runtime: Runtime<Config>) => {
  try {
    const payload: Payload =
      (runtime as any)?.event?.http?.bodyJSON ??
      (runtime as any)?.trigger?.http?.bodyJSON ??
      ({} as Payload);

    runtime.log(`HTTP payload: ${JSON.stringify(payload)}`);

    let bytesArgs = payload.bytesArgs;
    if (!bytesArgs) {
      if (!payload.txHash || !payload.rpcUrl) {
        runtime.log("❗ No bytesArgs or txHash/rpcUrl");
        return "no_bytes";
      }
      const receipt = await fetchTxReceipt(runtime, payload.rpcUrl, payload.txHash);
      bytesArgs = pickBytesArgsFromReceipt(receipt, payload, runtime);
      if (!bytesArgs || bytesArgs === "0x") {
        runtime.log("❗ bytesArgs is empty after fetching receipt");
        return "no_bytes";
      }
    }

    let packed: Uint8Array;
    try {
      packed = await buildPacked(bytesArgs);
    } catch (e) {
      runtime.log(`buildPacked failed: ${e instanceof Error ? e.message : String(e)}`);
      return "buildPacked_error";
    }
    runtime.log(`✅ buildPacked ok, length=${packed.length}`);

    const encodedPayload = hexToBase64(Buffer.from(packed).toString("hex"));
    const report: Report = runtime
      .report({
        encodedPayload,
        encoderName: "evm",
        signingAlgo: "ecdsa",
        hashingAlgo: "keccak256",
      })
      .result();

    runtime.log(`✅ report built seqNr=${report.x_generatedCodeOnly_unwrap().seqNr}`);

    if (payload.callbackUrl) {
      await sendReportSecureAxios(runtime, report, {
        url: payload.callbackUrl,
        keyId: payload.callbackKeyId ?? "dev",
        secretId: payload.callbackSecret ?? "CALLBACK_SIGNING_KEY",
        maxAgeMs: 60_000,
      });
      runtime.log(`📨 callback sent to ${payload.callbackUrl}`);
    } else {
      runtime.log("ℹ️ no callbackUrl, skipping callback step");
    }

    return "ok";
  } catch (err) {
    runtime.log(`🔥 fatal: ${err instanceof Error ? err.message : String(err)}`);
    return "error";
  }
};

export async function main() {
  const runner = await Runner.newRunner<Config>();

  await runner.run(() => {
    // ⚠️ Name of the capability may differ between SDK versions:
    const HttpCap =
      (cre as any).capabilities.HTTPTriggerCapability ??
      (cre as any).capabilities.HttpTriggerCapability ??
      (cre as any).capabilities.HTTPTrigger ??
      (cre as any).capabilities.HttpTrigger;

    if (!HttpCap) {
      throw new Error("HTTP Trigger capability not found in this SDK version");
    }

    const http = new HttpCap();

    // POST /message-report
    const trigger = http.trigger({ method: "POST", path: "/message-report" });

    return [cre.handler(trigger, onHttp)];
  });
}

main();
