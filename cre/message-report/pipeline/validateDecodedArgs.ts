import { Hex } from "viem";

import { DecodedArgs, DomainError, ErrorCode } from "../helpers";

function isValidMessageId(value: unknown): boolean {
	return typeof value === "string" && /^0x[a-fA-F0-9]{64}$/.test(value);
}

function isValidBlockNumber(value: unknown): boolean {
	if (typeof value !== "string") return false;

	if (!value.trim()) return false;

	try {
		const bn = BigInt(value);
		return bn > 0n;
	} catch {
		return false;
	}
}

function isValidChainSelector(value: unknown): boolean {
	return (
		typeof value === "number" && Number.isFinite(value) && Number.isInteger(value) && value > 0
	);
}

export function validateDecodedArgs(decodedArgs: DecodedArgs): void {
	if (!decodedArgs.batch.length) {
		throw new DomainError(ErrorCode.INVALID_DATA, "Batches list is empty");
	}

	const messageIds = new Set<Hex>();

	for (const item of decodedArgs.batch) {
		if (!isValidMessageId(item.messageId)) {
			throw new DomainError(
				ErrorCode.INVALID_MESSAGE_ID,
				"messageId must be a valid 32-byte hex string",
			);
		}

		if (messageIds.has(item.messageId)) {
			throw new DomainError(ErrorCode.INVALID_DATA, "Duplicated message already exists");
		}

		if (!isValidBlockNumber(item.blockNumber)) {
			throw new DomainError(
				ErrorCode.INVALID_DATA,
				"blockNumber must be a valid positive integer string",
			);
		}

		if (!isValidChainSelector(item)) {
			throw new DomainError(
				ErrorCode.INVALID_CHAIN_DATA,
				"srcChainSelector must be a finite positive integer",
			);
		}

		messageIds.add(item.messageId);
	}
}
