import { Runtime } from "@chainlink/cre-sdk";
import { Hex, maxUint64 } from "viem";

import { DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { ChainsManager } from "../systems";
import { ILatestBlockNumbers } from "./fetchBlockNumbers";
import { IParsedLog } from "./parseMessageSentLog";

const confirmationsError = (messageId: Hex) =>
	new DomainError(ErrorCode.EXPECTED_LOG_CONFIRMATIONS_NOT_REACHED, messageId);

export const validateBlockConfirmations = (
	log: IParsedLog,
	latestBlockNumbers: ILatestBlockNumbers,
) => {
	const chainsOptions = ChainsManager.getOptionsBySelector(log.receipt.srcChainSelector);

	let blockConfirmationsDelta: bigint;
	// if supported, use finalized blockNumber in the over cases use delta between log.blockNumber and chain.blockNumber
	if (log.receipt.srcChainData.blockConfirmations === maxUint64) {
		if (chainsOptions.finalityTagEnabled) {
			const lastFinalizedBlock = latestBlockNumbers[log.receipt.srcChainSelector].finalized;
			if (!lastFinalizedBlock) throw new DomainError(ErrorCode.LATEST_BLOCK_NOT_FETCHED);

			if (log.blockNumber > BigInt(lastFinalizedBlock)) {
				throw confirmationsError(log.data.messageId);
			}

			return;
		} else {
			blockConfirmationsDelta = BigInt(chainsOptions.finalityConfirmations);
		}
	} else if (log.receipt.srcChainData.blockConfirmations === 0n) {
		blockConfirmationsDelta = BigInt(chainsOptions.minBlockConfirmations);
	} else {
		blockConfirmationsDelta = log.receipt.srcChainData.blockConfirmations;
	}

	const actualChainBlock = latestBlockNumbers[log.receipt.srcChainSelector].latest;
	if (!actualChainBlock) throw new DomainError(ErrorCode.LATEST_BLOCK_NOT_FETCHED);

	if (log.blockNumber + blockConfirmationsDelta > actualChainBlock) {
		throw confirmationsError(log.data.messageId);
	}
};

export function validateMessagesBlockConfirmations(
	runtime: Runtime<GlobalConfig>,
	parsedLogs: IParsedLog[],
	latestBlockNumbers: ILatestBlockNumbers,
) {
	const validMessages = [];

	for (const log of parsedLogs) {
		try {
			validateBlockConfirmations(log, latestBlockNumbers);
			validMessages.push(log);
		} catch (e) {
			runtime.log(
				`Validate block confirmations error: ${JSON.stringify(e instanceof Error ? e.message : e)}`,
			);
		}
	}

	return validMessages;
}
