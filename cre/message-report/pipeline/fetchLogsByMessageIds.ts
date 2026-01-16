import { Runtime } from "@chainlink/cre-sdk";
import { type Log, encodeEventTopics, toHex } from "viem";

import { ConceroMessageSentEvent } from "../abi";
import { DecodedArgs, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { IRpcRequest, RpcRequester } from "../helpers/RpcRequester";
import { ChainsManager } from "../systems";

const LOG_TAG = "FETCH_LOG";

function buildGetLogsReqParams(
	runtime: Runtime<GlobalConfig>,
	items: DecodedArgs["batch"],
): IRpcRequest[] {
	const reqParams = [];

	for (const item of items) {
		const fromBlock = BigInt(item.blockNumber) - 10n;
		const toBlock = BigInt(item.blockNumber);

		const routerAddress = ChainsManager.getOptionsBySelector(item.srcChainSelector)?.deployments
			?.router;

		if (!routerAddress) {
			runtime.log(`Router deployment not found for chain ${item.srcChainSelector}`);
			continue;
		}

		runtime.log(`Got routerAddress=${routerAddress}`);
		runtime.log(
			`${LOG_TAG} Fetching ${JSON.stringify({
				routerAddress,
				messageId: item.messageId,
				fromBlock: String(fromBlock),
				toBlock: String(toBlock),
			})}`,
		);

		reqParams.push({
			chainSelector: item.srcChainSelector,
			method: "eth_getLogs",
			params: [
				{
					address: routerAddress,
					fromBlock: toHex(fromBlock),
					toBlock: toHex(toBlock),
					topics: [
						encodeEventTopics({
							abi: [ConceroMessageSentEvent.eventAbi],
							args: { messageId: item.messageId },
						}),
					],
				},
			],
		});
	}

	return reqParams;
}

export function fetchLogsByMessageIds(
	runtime: Runtime<GlobalConfig>,
	rpcRequester: RpcRequester,
	items: DecodedArgs["batch"],
): Log[] {
	rpcRequester.batchAdd(buildGetLogsReqParams(runtime, items));
	const logs = rpcRequester.wait();

	if (!logs?.length) {
		runtime.log(`${LOG_TAG} Logs are empty`);
		throw new DomainError(ErrorCode.LOGS_NOT_FOUND, "Logs are empty");
	}

	// TODO: double check if log really exists
	return logs.map(res => res[0]);

	// TODO: move to top level
	// const log = logs?.find(log => {
	// 	const logMessageId = log?.topics?.[1]?.toLowerCase();
	// 	return logMessageId === messageId?.toLowerCase();
	// });
	//
	// if (!log) {
	// 	runtime.log(`${LOG_TAG} Log not found`);
	// 	throw new DomainError(ErrorCode.EVENT_NOT_FOUND);
	// }
}
