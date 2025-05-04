import { Address, type PublicClient, decodeEventLog } from "viem";

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

	const conceroMessageSentLog = logs.find(currLog => {
		try {
			const { args } = decodeEventLog({
				abi: ConceroMessageLogParams,
				data: currLog.data,
			}); 

			return args.messageId.toLowerCase() === messageId.toLowerCase();
		} catch {
			return false;
		}
	});

	if (!conceroMessageSentLog) handleError(ErrorType.EVENT_NOT_FOUND);

	return conceroMessageSentLog;
}
