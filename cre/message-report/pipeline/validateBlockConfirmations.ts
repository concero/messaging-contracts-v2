import { PublicClient, maxUint64 } from "viem";

import { DecodedMessageSentReceipt, DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

export const validateBlockConfirmations = async (
	logBlockNumber: bigint,
	logParsedReceipt: DecodedMessageSentReceipt,
	client: PublicClient,
): Promise<void> => {
	const chainsOptions = ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector);

	const actualChainBlock = await client.getBlock({
		blockTag: chainsOptions.finalityTagEnabled ? "finalized" : "latest",
	});

	let blockConfirmationsDelta: bigint;
	if (
		logParsedReceipt.srcChainData.blockConfirmations === maxUint64 ||
		chainsOptions.finalityTagEnabled
	) {
		blockConfirmationsDelta = BigInt(chainsOptions.finalityConfirmations);
	} else if (logParsedReceipt.srcChainData.blockConfirmations === 0n) {
		blockConfirmationsDelta = BigInt(chainsOptions.minBlockConfirmations);
	} else {
		blockConfirmationsDelta = logParsedReceipt.srcChainData.blockConfirmations;
	}

	if (logBlockNumber + blockConfirmationsDelta > BigInt(actualChainBlock.number)) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "Not enough block confirmations");
	}
};
