import { maxUint64 } from "viem";

import { DecodedMessageSentReceipt, DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

export const validateBlockConfirmations = (
	logBlockNumber: bigint,
	logParsedReceipt: DecodedMessageSentReceipt,
	currentChainBlockNumber: bigint,
): void => {
	let blockConfirmationsDelta: bigint = 0n;
	if (logParsedReceipt.srcChainData.blockConfirmations === 0n) {
		blockConfirmationsDelta = BigInt(
			ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector)
				.minBlockConfirmations,
		);
	} else if (logParsedReceipt.srcChainData.blockConfirmations === maxUint64) {
		blockConfirmationsDelta = BigInt(
			ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector)
				.finalityConfirmations,
		);
	} else {
		blockConfirmationsDelta = logParsedReceipt.srcChainData.blockConfirmations;
	}

	if (logBlockNumber + blockConfirmationsDelta > currentChainBlockNumber) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "Not enough block confirmations");
	}
};
