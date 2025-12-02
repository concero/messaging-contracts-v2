import { DecodedMessageSentReceipt, DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

const UINT64_MAX = 18446744073709551615n;

export const validateBlockConfirmations = (
	logBlockNumber: bigint,
	logParsedReceipt: DecodedMessageSentReceipt,
	currentChainBlockNumber: bigint,
): void => {
	if (logParsedReceipt.srcChainData.blockConfirmations === 0n) {
		return;
	}

	let finalityBlockConfirmations: bigint = 0n;
	if (logParsedReceipt.srcChainData.blockConfirmations !== UINT64_MAX) {
		finalityBlockConfirmations = logParsedReceipt.srcChainData.blockConfirmations;
	} else {
		finalityBlockConfirmations = BigInt(
			ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector)
				.finalityConfirmations ?? 0,
		);
	}
	if (logBlockNumber + finalityBlockConfirmations < currentChainBlockNumber) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "Block was not finalized ");
	}
};
