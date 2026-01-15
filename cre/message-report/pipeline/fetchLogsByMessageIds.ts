import { HTTPSendRequester, Runtime } from "@chainlink/cre-sdk";
import { type Log, encodeEventTopics, toHex } from "viem";

import { ConceroMessageSentEvent } from "../abi";
import { CRE, DecodedArgs, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { headers } from "../helpers/constants";
import { ChainsManager } from "../systems";

const LOG_TAG = "FETCH_LOG";

function buildGetLogsReqParams(
	runtime: Runtime<GlobalConfig>,
	items: DecodedArgs["batch"],
): CRE.IFetcherOptions[] {
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

		const body = {
			id: "1",
			jsonrpc: "2.0",
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
		};

		reqParams.push({
			method: "POST",
			url: ChainsManager.getOptionsBySelector(item.srcChainSelector).rpcUrls[0],
			headers,
			body: new TextEncoder().encode(JSON.stringify(body)),
		});
	}

	return reqParams;
}

export function fetchLogsByMessageIds(
	runtime: Runtime<GlobalConfig>,
	sendRequester: HTTPSendRequester,
	items: DecodedArgs["batch"],
): Log[] {
	try {
		const getLogsReqParams = buildGetLogsReqParams(runtime, items);
		const logsPromises = CRE.buildSendRequestPromises(sendRequester, getLogsReqParams);

		// if (!logs?.length) {
		// 	runtime.log(`${LOG_TAG} Logs are empty (length=${logs.length}) `);
		// 	throw new DomainError(ErrorCode.EVENT_NOT_FOUND, "Logs are empty");
		// }
		//
		// const log = logs?.find(log => {
		// 	const logMessageId = log?.topics?.[1]?.toLowerCase();
		// 	return logMessageId === messageId?.toLowerCase();
		// });
		//
		// if (!log) {
		// 	runtime.log(`${LOG_TAG} Log not found`);
		// 	throw new DomainError(ErrorCode.EVENT_NOT_FOUND);
		// }
		//

		return CRE.fulfillSendRequestPromises(logsPromises).map(rawLog => rawLog.result[0]);
	} catch (e) {
		runtime.log(`${LOG_TAG} Logs request failed`);
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, `${LOG_TAG} Logs request failed. ${e}`);
	}
}
