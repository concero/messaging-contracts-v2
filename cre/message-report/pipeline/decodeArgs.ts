import { HTTPPayload, decodeJson } from "@chainlink/cre-sdk";
import { type Hex } from "viem";

import { type DecodedArgs, DomainError, ErrorCode } from "../helpers";

export function decodeArgs(payload: HTTPPayload): DecodedArgs {
	try {
		const data: Record<string, unknown> = decodeJson(payload.input);
		const rawList = (data?.batches || []) as DecodedArgs["batch"];

		const batch = rawList.map(batch => ({
			messageId: batch.messageId as Hex,
			srcChainSelector: Number(batch.srcChainSelector),
			blockNumber: batch.blockNumber,
		}));

		return {
			batch,
		};
	} catch (e) {
		throw new DomainError(ErrorCode.INVALID_DATA);
	}
}
