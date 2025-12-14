import { Hex } from "viem";

import { DecodedArgs, DomainError, ErrorCode } from "../helpers";

export function validateDecodedArgs(decodedArgs: DecodedArgs): void {
	if (!decodedArgs.batch.length) {
		throw new DomainError(ErrorCode.INVALID_DATA, "Batches list is empty");
	}

	const messageIds = new Set<Hex>();

	for (const batch of decodedArgs.batch) {
		if (messageIds.has(batch.messageId)) {
			throw new DomainError(ErrorCode.INVALID_DATA, "Message duplicated already exists");
		}

		if (!batch.messageId || batch.messageId.length === 0) {
			throw new DomainError(ErrorCode.INVALID_MESSAGE_ID);
		}

		if (!batch.blockNumber) {
			throw new DomainError(ErrorCode.INVALID_DATA);
		}

		if (!batch.srcChainSelector) {
			throw new DomainError(ErrorCode.INVALID_CHAIN_DATA);
		}

		messageIds.add(batch.messageId);
	}
}
