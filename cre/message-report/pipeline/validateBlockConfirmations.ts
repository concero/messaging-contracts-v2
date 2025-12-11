import { DecodedMessageSentReceipt, DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

export const validateBlockConfirmations = (
	logBlockNumber: bigint,
	logParsedReceipt: DecodedMessageSentReceipt,
	currentChainBlockNumber: bigint,
): void => {
	if (logParsedReceipt.srcChainData.blockConfirmations === 0n) {
		return;
	}

	const requestedBlockConfirmations = logParsedReceipt.srcChainData.blockConfirmations;
	const finalityBlockConfirmations = BigInt(
		ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector)
			.finalityConfirmations || 0,
	);

	const blockConfirmationsDelta =
		requestedBlockConfirmations > finalityBlockConfirmations
			? requestedBlockConfirmations
			: finalityBlockConfirmations;

	if (logBlockNumber + blockConfirmationsDelta < currentChainBlockNumber) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "Not enough block confirmations");
	}
};
