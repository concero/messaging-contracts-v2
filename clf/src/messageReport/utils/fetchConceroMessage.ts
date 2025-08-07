import { Address, type PublicClient } from "viem";

import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { ConceroMessageLogParams, conceroMessageSentEventName } from "../constants/abis";

export async function fetchConceroMessage(
	client: PublicClient,
	routerAddress: Address,
	messageId: string,
	blockNumber: bigint,
) {
	const logs = await client.getLogs({
		event: { type: "event", inputs: ConceroMessageLogParams, name: conceroMessageSentEventName },
		address: routerAddress,
		fromBlock: blockNumber - 10n,
		toBlock: blockNumber,
	});

	if (!logs.length) handleError(ErrorType.EVENT_NOT_FOUND);

	const conceroMessageSentLog = logs.find(log => log.topics[1]?.toLowerCase() === messageId.toLowerCase());

	if (!conceroMessageSentLog) handleError(ErrorType.EVENT_NOT_FOUND);

	return conceroMessageSentLog;
}
