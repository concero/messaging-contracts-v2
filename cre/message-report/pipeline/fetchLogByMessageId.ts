import { Runtime } from "@chainlink/cre-sdk";
import { type Address, type Log, type PublicClient } from "viem";

import { ConceroMessageSentEvent } from "../abi";
import { DomainError, ErrorCode, GlobalConfig } from "../helpers";

const LOG_TAG = "FETCH_LOG";

export async function fetchLogByMessageId(
	runtime: Runtime<GlobalConfig>,
	client: PublicClient,
	address: Address,
	messageId: string,
	blockNumber: bigint,
): Promise<Log> {
	const fromBlock = blockNumber - 10n;
	const toBlock = blockNumber;

	runtime.log(
		`${LOG_TAG} Fetching ${JSON.stringify({
			address,
			messageId,
			fromBlock: String(fromBlock),
			toBlock: String(toBlock),
		})}`,
	);
	let logs: Log[] = [];

	try {
		logs = await client.getLogs({
			event: {
				type: "event",
				inputs: ConceroMessageSentEvent.inputs,
				name: ConceroMessageSentEvent.name,
			},
			address,
			fromBlock,
			toBlock,
		});

		runtime.log(`${LOG_TAG} Fetched successfully`);
	} catch (e) {
		runtime.log(`${LOG_TAG} Logs request failed`);
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, `${LOG_TAG} Logs request failed. ${e}`);
	}

	if (!logs?.length) {
		runtime.log(`${LOG_TAG} Logs are empty (length=${logs.length}) `);
		throw new DomainError(ErrorCode.EVENT_NOT_FOUND, "Logs are empty");
	}

	const log = logs?.find(log => {
		const logMessageId = log?.topics?.[1]?.toLowerCase();
		return logMessageId === messageId?.toLowerCase();
	});

	if (!log) {
		runtime.log(`${LOG_TAG} Log not found`);
		throw new DomainError(ErrorCode.EVENT_NOT_FOUND);
	}

	return log;
}
