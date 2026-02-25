import { Runtime } from "@chainlink/cre-sdk";
import { Hex, type Log, encodeEventTopics, toHex } from "viem";

import { ConceroMessageSentEvent } from "../abi";
import { DecodedArgs, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { defaultGetLogsBlockDepth } from "../helpers/constants";
import { IRpcRequest, RpcRequester } from "../helpers/RpcRequester";
import { ChainSelector, ChainsManager, DeploymentAddress } from "../systems";

export interface IFetchLogsResult {
	chainSelector: ChainSelector;
	log: Log;
}

interface ILogGroup {
	chainSelector: ChainSelector;
	routerAddress: DeploymentAddress;
	messageIds: Hex[];
	minBlock: bigint;
	maxBlock: bigint;
}

const LOG_TAG = "FETCH_LOG";

function groupItemsByChainAndProximity(
	runtime: Runtime<GlobalConfig>,
	items: DecodedArgs["batch"],
): ILogGroup[] {
	const byChain = new Map<ChainSelector, DecodedArgs["batch"]>();

	for (const item of items) {
		const chain = ChainsManager.getOptionsBySelector(item.srcChainSelector);

		if (!chain?.deployments?.router) {
			runtime.log(`Router deployment not found for chain ${item.srcChainSelector}`);
			continue;
		}

		if (!chain.rpcUrls?.length) {
			runtime.log(`Rpcs for chain ${item.srcChainSelector} not found`);
			continue;
		}

		const existing = byChain.get(item.srcChainSelector);
		if (existing) {
			existing.push(item);
		} else {
			byChain.set(item.srcChainSelector, [item]);
		}
	}

	const groups: ILogGroup[] = [];

	for (const [chainSelector, chainItems] of byChain) {
		const chain = ChainsManager.getOptionsBySelector(chainSelector);
		const routerAddress = chain.deployments.router!;
		const blockDepth = BigInt(chain.getLogsBlockDepth ?? Number(defaultGetLogsBlockDepth));

		chainItems.sort((a, b) => Number(BigInt(a.blockNumber) - BigInt(b.blockNumber)));

		let currentGroup: ILogGroup = {
			chainSelector,
			routerAddress,
			messageIds: [chainItems[0].messageId],
			minBlock: BigInt(chainItems[0].blockNumber),
			maxBlock: BigInt(chainItems[0].blockNumber),
		};

		for (let i = 1; i < chainItems.length; i++) {
			const block = BigInt(chainItems[i].blockNumber);
			// +10n accounts for the fromBlock offset (minBlock - 10n)
			if (block - currentGroup.minBlock + 10n <= blockDepth) {
				currentGroup.messageIds.push(chainItems[i].messageId);
				if (block > currentGroup.maxBlock) currentGroup.maxBlock = block;
			} else {
				groups.push(currentGroup);
				currentGroup = {
					chainSelector,
					routerAddress,
					messageIds: [chainItems[i].messageId],
					minBlock: block,
					maxBlock: block,
				};
			}
		}

		groups.push(currentGroup);
	}

	return groups;
}

function buildGetLogsReqParams(
	runtime: Runtime<GlobalConfig>,
	items: DecodedArgs["batch"],
): IRpcRequest[] {
	const groups = groupItemsByChainAndProximity(runtime, items);
	const [eventSignature] = encodeEventTopics({
		abi: [ConceroMessageSentEvent.eventAbi],
	});
	const reqParams: IRpcRequest[] = [];

	for (const group of groups) {
		const fromBlock = group.minBlock - 10n;
		const toBlock = group.maxBlock;
		const messageIdsTopic =
			group.messageIds.length === 1 ? group.messageIds[0] : group.messageIds;

		runtime.log(
			`${LOG_TAG} Fetching ${JSON.stringify({
				routerAddress: group.routerAddress,
				messageIds: group.messageIds.length,
				fromBlock: String(fromBlock),
				toBlock: String(toBlock),
			})}`,
		);

		reqParams.push({
			chainSelector: group.chainSelector,
			method: "eth_getLogs",
			params: [
				{
					address: group.routerAddress,
					fromBlock: toHex(fromBlock),
					toBlock: toHex(toBlock),
					topics: [eventSignature, messageIdsTopic],
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
