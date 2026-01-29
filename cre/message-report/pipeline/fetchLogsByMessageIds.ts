import { Runtime } from "@chainlink/cre-sdk";
import { type Log, encodeEventTopics, toHex } from "viem";

import { ConceroMessageSentEvent } from "../abi";
import { DecodedArgs, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { IRpcRequest, RpcRequester } from "../helpers/RpcRequester";
import { ChainSelector, ChainsManager } from "../systems";

export interface IFetchLogsResult {
	chainSelector: ChainSelector;
	log: Log;
}

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

		const rpcUrls = ChainsManager.getOptionsBySelector(item.srcChainSelector)?.rpcUrls;
		if (!rpcUrls?.length) {
			runtime.log(`Rpcs for chain ${item.srcChainSelector} not found`);
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

function buildResponse(
	runtime: Runtime<GlobalConfig>,
	items: DecodedArgs["batch"],
	logs: (Log[] | null)[],
) {
	const response = [];
	const itemsMap = items.reduce((acc, i) => {
		acc[i.messageId.toLowerCase()] = i;
		return acc;
	}, {});

	for (const log of logs) {
		if (!log) continue;
		for (const l of log) {
			const logRes = itemsMap[l.topics[1].toLowerCase()];
			if (!logRes) continue;

			response.push({
				log: l,
				chainSelector: logRes.chainSelector,
			});
		}
	}

	return response;
}

export function fetchLogsByMessageIds(
	runtime: Runtime<GlobalConfig>,
	rpcRequester: RpcRequester,
	items: DecodedArgs["batch"],
): (IFetchLogsResult | null)[] {
	rpcRequester.batchAdd(buildGetLogsReqParams(runtime, items));
	const logs = rpcRequester.wait();

	if (!logs?.length) {
		runtime.log(`${LOG_TAG} Logs are empty`);
		throw new DomainError(ErrorCode.LOGS_NOT_FOUND, "Logs are empty");
	}

	return buildResponse(runtime, items, logs);
}
