import { Address, type PublicClient } from "viem";

import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";

export async function fetchConceroMessage(
	client: PublicClient,
	routerAddress: Address,
	messageId: string,
	blockNumber: bigint,
) {
	const logs = await client.getLogs({
		address: routerAddress,
		topics: [null, messageId],
		fromBlock: blockNumber - 10n,
		toBlock: blockNumber,
	});
	if (!logs.length) handleError(ErrorType.EVENT_NOT_FOUND);

	return logs[0];
}
