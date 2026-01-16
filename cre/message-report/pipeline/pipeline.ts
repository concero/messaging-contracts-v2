import {
	HTTPPayload,
	HTTPSendRequester,
	Runtime,
	consensusIdenticalAggregation,
	cre,
} from "@chainlink/cre-sdk";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { Hex, Log } from "viem";

import { DecodedArgs, GlobalConfig, Utility } from "../helpers";
import { RpcRequester } from "../helpers/RpcRequester";
import { ChainsManager } from "../systems";
import { buildValidation } from "./buildValidation";
import { decodeArgs } from "./decodeArgs";
import { fetchLogsByMessageIds } from "./fetchLogsByMessageIds";
import { generateReport } from "./generateReport";
import { parseMessageSentLog } from "./parseMessageSentLog";
import { sendReportsToRelayer } from "./sendReportsToRelayer";
import { validateDecodedArgs } from "./validateDecodedArgs";
import { validateMessageVersion } from "./validateMessageVersion";
import { validateValidatorLib } from "./validateValidatorLib";

let merkleTree: StandardMerkleTree<Hex[]>;
let messageIds: Hex[];

function parseLogs(runtime: Runtime<GlobalConfig>, logs: Log[]) {
	const parsedLogs = [];
	for (const log of logs) {
		const parsedLog = parseMessageSentLog(log);

		runtime.log(
			`Got log txHash=${log.transactionHash}, ${Utility.safeJSONStringify(parsedLog)}`,
		);
		validateMessageVersion(parsedLog.receipt.version, runtime);
		// validateBlockConfirmations(parsedLog.blockNumber, parsedLog.receipt, publicClient, runtime);
		validateValidatorLib(parsedLog.receipt.srcChainSelector, parsedLog.data.validatorLibs);
		// if (!log || !log?.data) {
		// 	runtime.log(`Log where messageId=${parsedLog.data.messageId} not found`);
		// }

		parsedLogs.push(parsedLog);
	}
	return parsedLogs;
}

function fetchMessagesAndGenerateProof(
	runtime: Runtime<GlobalConfig>,
	args: DecodedArgs,
	chainsConfigHash: Hex,
) {
	return (sendRequester: HTTPSendRequester) => {
		ChainsManager.enrichOptions(runtime, sendRequester, chainsConfigHash);

		const rpcRequester = new RpcRequester(
			Object.fromEntries(
				[...new Set(args.batch.map(i => i.srcChainSelector))].map(s => [
					s,
					ChainsManager.getOptionsBySelector(s).rpcUrls,
				]),
			),
			sendRequester,
		);

		const logs = fetchLogsByMessageIds(runtime, rpcRequester, args.batch);
		const parsedLogs = parseLogs(runtime, logs);

		messageIds = parsedLogs.map(log => log.data.messageId);
		merkleTree = StandardMerkleTree.of(
			messageIds.map(id => [id]),
			["bytes32"],
		);

		return merkleTree.root;
	};
}

// pipeline stages for each validation request
export async function pipeline(runtime: Runtime<GlobalConfig>, payload: HTTPPayload) {
	try {
		const args = decodeArgs(payload);
		runtime.log(`Decoded args: ${JSON.stringify(args)}`);
		validateDecodedArgs(args);

		const chainsConfigHash = runtime
			.getSecret({ id: "CHAINS_CONFIG_HASHSUM" })
			.result()
			.value.toLowerCase() as Hex;

		const merkleRoot = new cre.capabilities.HTTPClient()
			.sendRequest(
				runtime,
				fetchMessagesAndGenerateProof(runtime, args, chainsConfigHash),
				consensusIdenticalAggregation<any>(),
			)()
			.result();

		const report = generateReport(runtime, merkleRoot);
		const validation = buildValidation(report, messageIds, merkleTree);

		sendReportsToRelayer(runtime, validation);

		return "success";
	} catch (error) {
		runtime.log(
			`Pipeline failed with error ${error instanceof Error ? `${error.message} ${error.stack}` : error?.toString()}`,
		);
	}
}
