import { CONFIG } from "./constants/config";

import { ResultType } from "../common/enums";
import { getPublicClient } from "../common/viemClient";
import { conceroRouters } from "./constants/conceroRouters";
import { fetchConceroMessage } from "./utils/fetchConceroMessage";
import { packResult } from "./utils/packResult";
import { decodeInputs } from "./utils/validateInputs";
import { verifyMessage } from "./utils/verifyMessageHash";
import { Hex, hexToBytes, sha256 } from "viem";

type BytesLike = Uint8Array | `0x${string}`;

export type Callbacks = {
  onFetched?(log: unknown): void;
  onVerified?(hash: Hex, unsignedReport: unknown): void;
  onPacked?(packed: Uint8Array): void;
  onError?(e: unknown): void;
};

export type Options = {
  router?: `0x${string}`;
};

function stableStringify(value: any): string {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(",")}]`;
  const keys = Object.keys(value).sort();
  const entries = keys.map((k) => `${JSON.stringify(k)}:${stableStringify(value[k])}`);
  return `{${entries.join(",")}}`;
}

export async function main(bytesArgsInput: BytesLike, cbs: Callbacks = {}, opts: Options = {}) {
  try {
    const bytes = typeof bytesArgsInput === "string" ? hexToBytes(bytesArgsInput) : bytesArgsInput;
    const args = decodeInputs(bytes);

    const publicClient = getPublicClient(args.srcChainSelector.toString());
    const router = opts.router ?? conceroRouters[Number(args.srcChainSelector)];

    const log = await fetchConceroMessage(
      publicClient,
      router,
      args.messageId,
      BigInt(args.srcChainData.blockNumber)
    );
    cbs.onFetched?.(log);

    verifyMessage(log);

    const unsignedReport = {
      payloadVersion: CONFIG.PAYLOAD_VERSION,
      resultType: ResultType.MESSAGE,
      requester: args.operatorAddress,
      messageId: args.messageId,
      srcChainSelector: args.srcChainSelector,
      srcBlockNumber: log.blockNumber,
      rawLog: {
        address: log.address,
        data: log.data,
        topics: log.topics,
        blockNumber: log.blockNumber,
        transactionHash: log.transactionHash,
        logIndex: log.logIndex,
      },
    };

    const messageHashSum = sha256(new TextEncoder().encode(stableStringify(unsignedReport)));
    cbs.onVerified?.(messageHashSum, unsignedReport);

    const messageReportResult = {
      ...unsignedReport,
      messageHashSum,
    };

    const packed = packResult(messageReportResult);
    cbs.onPacked?.(packed);

    return packed;
  } catch (e) {
    cbs.onError?.(e);
    throw e;
  }
}
