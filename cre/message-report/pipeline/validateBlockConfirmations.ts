import { PublicClient, maxUint64 } from "viem";

import { DecodedMessageSentReceipt, DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

const confirmationsError = new DomainError(
	ErrorCode.UNKNOWN_ERROR,
	"Not enough block confirmations",
);

export const validateBlockConfirmations = async (
	logBlockNumber: bigint,
	logParsedReceipt: DecodedMessageSentReceipt,
	client: PublicClient,
): Promise<void> => {
	const chainsOptions = ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector);

	let blockConfirmationsDelta: bigint;
	// if supported, use finalized blockNumber in the over cases use delta between log.blockNumber and chain.blockNumber
	if (logParsedReceipt.srcChainData.blockConfirmations === maxUint64) {
		if (chainsOptions.finalityTagEnabled) {
			const lastFinalizedBlock = await client.getBlock({
				blockTag: "finalized",
			});

			if (logBlockNumber > BigInt(lastFinalizedBlock.number)) {
				throw confirmationsError;
			}

			return;
		} else {
			blockConfirmationsDelta = BigInt(chainsOptions.finalityConfirmations);
		}
	} else if (logParsedReceipt.srcChainData.blockConfirmations === 0n) {
		blockConfirmationsDelta = BigInt(chainsOptions.minBlockConfirmations);
	} else {
		blockConfirmationsDelta = logParsedReceipt.srcChainData.blockConfirmations;
	}

	const actualChainBlock = await client.getBlockNumber();

	if (logBlockNumber + blockConfirmationsDelta > actualChainBlock) {
		throw confirmationsError;
	}
};
