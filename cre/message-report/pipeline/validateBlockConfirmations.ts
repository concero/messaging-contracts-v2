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

	const requestedFinalityBlockNumbers = logParsedReceipt.srcChainData.blockConfirmations;
	const protocolFinalityBlockNumber = BigInt(
		ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector)
			.finalityConfirmations || 0,
	);

	const finalityBlocksDelta =
		requestedFinalityBlockNumbers > protocolFinalityBlockNumber
			? requestedFinalityBlockNumbers
			: protocolFinalityBlockNumber;

	if (logBlockNumber + finalityBlocksDelta < currentChainBlockNumber) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "Block was not finalized");
	}
};
