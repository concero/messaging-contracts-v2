import { Runtime } from "@chainlink/cre-sdk";
import { maxUint64 } from "viem";

import { GlobalConfig } from "../helpers";
import { IRpcRequest, IRpcResponse, RpcRequester } from "../helpers/RpcRequester";
import { ChainSelector, ChainsManager } from "../systems";
import { IParsedLog } from "./parseMessageSentLog";

export type ILatestBlockNumbers = Record<number, { latest?: bigint; finalized?: bigint }>;

type ILatestBlockRequest = Record<number, { latest: boolean; finalized: boolean }>;

const getLatestBlockNumberTag = "eth_blockNumber";
const getFinalizedBlockTag = "eth_getBlockByNumber";

function buildUniqRequests(parsedLogs: IParsedLog[]) {
	const requests: ILatestBlockRequest = {};

	parsedLogs.forEach(log => {
		requests[log.receipt.srcChainSelector] = { latest: false, finalized: false };

		if (
			log.receipt.srcChainData.blockConfirmations === maxUint64 &&
			ChainsManager.getOptionsBySelector(log.chainSelector).finalityTagEnabled
		) {
			requests[log.receipt.srcChainSelector].finalized = true;
		} else {
			requests[log.receipt.srcChainSelector].latest = true;
		}
	});

	return requests;
}

function buildBlockNumberRequests(requests: ILatestBlockRequest) {
	let results = [];

	const getLatestBlockReq = (chainSelector: ChainSelector) => ({
		chainSelector,
		method: getLatestBlockNumberTag,
		params: [],
	});

	const getFinalizedBlockReq = (chainSelector: ChainSelector) => ({
		chainSelector,
		method: getFinalizedBlockTag,
		params: ["finalized"],
	});

	for (const chainSelector in requests) {
		if (requests[chainSelector].latest) results.push(getLatestBlockReq(Number(chainSelector)));
		if (requests[chainSelector].finalized)
			results.push(getFinalizedBlockReq(Number(chainSelector)));
	}

	return results;
}

function buildLastBlockNumbersResponse(
	blockNumberRequests: IRpcRequest[],
	results: (IRpcResponse | null)[],
) {
	const blockNumbers: ILatestBlockNumbers = {};
	blockNumberRequests.forEach((req, i) => {
		if (!results[i]) return;

		blockNumbers[req.chainSelector] = {};

		const blockType =
			blockNumberRequests[i].method === getLatestBlockNumberTag ? "latest" : "finalized";
		const blockNumber =
			blockType === "finalized" ? BigInt(results[i].number) : BigInt(results[i]);
		blockNumbers[req.chainSelector][blockType] = blockNumber;
	});

	return blockNumbers;
}

export function fetchBlockNumbers(
	runtime: Runtime<GlobalConfig>,
	rpcRequester: RpcRequester,
	parsedLogs: IParsedLog[],
): ILatestBlockNumbers {
	const uniqRequests = buildUniqRequests(parsedLogs);
	const blockNumberRequests = buildBlockNumberRequests(uniqRequests);

	rpcRequester.batchAdd(blockNumberRequests);

	return buildLastBlockNumbersResponse(blockNumberRequests, rpcRequester.wait());
}
