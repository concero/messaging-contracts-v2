import {
  cre,
  Runner,
  hexToBase64,
  type Runtime,
} from "@chainlink/cre-sdk";

import { main as buildPacked } from "../../../../src/messageReport/messageReport";
import cfg from "../../config.json";
import { sendReportSecure } from "../../../../src/messageReport/utils/sendCallbackSecure";
import { toHex } from "viem";

const onEvmEvent = async (runtime: Runtime<Record<string, never>>) => {
  try {
    runtime.log("CRE workflow started (onEvmEvent)");

    const evmLog = (runtime as any)?.event?.evmLog ?? (runtime as any)?.trigger?.evmLog;
    let bytesArgs: `0x${string}` | undefined = evmLog?.data;

    if (!bytesArgs || bytesArgs === "0x") {
      runtime.log("⚠️ No evmLog.data detected — using mock payload for simulation");
      bytesArgs = "0x" + "11".repeat(64) as `0x${string}`;
    }

    let packed: Uint8Array;
    try {
      packed = await buildPacked(bytesArgs);
    } catch (e) {
      runtime.log(`buildPacked failed: ${e instanceof Error ? e.message : e}`);
      return "buildPacked_error";
    }

    runtime.log(`✅ buildPacked ok, length=${packed.length}`);

    const encodedPayload = hexToBase64(toHex(packed).slice(2));

    const report = runtime
      .report({
        encodedPayload,
        encoderName: "evm",
        signingAlgo: "ecdsa",
        hashingAlgo: "keccak256",
      })
      .result();

    runtime.log(
      `✅ Report built seqNr=${report.seqNr}`
    );

    if ((cfg as any).callbackUrl) {
      sendReportSecure(runtime, report, {
        url: (cfg as any).callbackUrl,
        keyId: (cfg as any).callbackKeyId ?? "dev",
        secretId: (cfg as any).callbackSecretId ?? "CALLBACK_SIGNING_KEY",
        maxAgeMs: 60_000,
      });
      runtime.log(`Report sent to ${(cfg as any).callbackUrl}`);
    }

    return "ok";
  } catch (err) {
    runtime.log(`🔥 workflow fatal: ${err instanceof Error ? err.message : err}`);
    return "error";
  }
};

export async function main() {
  const runner = await Runner.newRunner<Record<string, never>>({});

  await runner.run(() => {
    const EVM =
      (cre as any).capabilities.EVMEventCapability ??
      (cre as any).capabilities.EVMLogCapability;

    const evm = new EVM();

    return [
      cre.handler(
        evm.trigger({
          chainSelector: 16015286601757825753,
          eventSignature: "MessageReceived(bytes32,address)",
          contractAddress: "0x0000000000000000000000000000000000000000",
          logTopics: []
        }),
        onEvmEvent
      ),
    ];
  });
}

