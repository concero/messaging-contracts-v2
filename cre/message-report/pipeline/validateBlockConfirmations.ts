import { DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";
import { MessagingCodec } from "./codec";
import { fetchLogByMessageId } from "./fetchLogByMessageId";

const UINT64_MAX = 18446744073709551615n;

export const validateBlockConfirmations = (
	log: Awaited<ReturnType<typeof fetchLogByMessageId>>,
	currentChainBlockNumber: bigint,
): void => {
	const parsedReceipt = MessagingCodec.decodeReceipt(log.data.messageReceipt);

	if (parsedReceipt.srcChainData.blockConfirmations === 0n) {
		return;
	}

	let finalityBlockConfirmations: bigint = 0n;
	if (parsedReceipt.srcChainData.blockConfirmations === UINT64_MAX) {
		finalityBlockConfirmations = parsedReceipt.srcChainData.blockConfirmations;
	} else {
		finalityBlockConfirmations = BigInt(
			ChainsManager.getOptionsBySelector(parsedReceipt.srcChainSelector)
				.finalityConfirmations ?? 0,
		);
	}
	if ((log.blockNumber || 0n) + finalityBlockConfirmations < currentChainBlockNumber) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "Block was not finalized ");
	}
};
