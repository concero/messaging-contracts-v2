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

	const requestBlockNumbers = Number(logParsedReceipt.srcChainData.blockConfirmations);
	const configBlockNumber =
		ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector)
			.finalityConfirmations || 0;

	const finalityBlocksDelta = Math.max(requestBlockNumbers, configBlockNumber);
	if (logBlockNumber + BigInt(finalityBlocksDelta) < currentChainBlockNumber) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "Block was not finalized");
	}
};
