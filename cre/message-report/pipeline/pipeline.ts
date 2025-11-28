import { HTTPPayload, Report, Runtime } from "@chainlink/cre-sdk";
import { keccak256 } from "viem";

import { DecodedArgs, DomainError, ErrorCode, GlobalConfig, Utility } from "../helpers";
import { ChainsManager, PublicClient } from "../systems";
import { buildResponseFromBatches } from "./buildResponseFromBatches";
import { decodeArgs } from "./decodeArgs";
import { fetchLogByMessageId } from "./fetchLogByMessageId";
import { parseMessageSentLog } from "./parseMessageSentLog";
import { sendReportsToRelayer } from "./sendReportsToRelayer";
import { validateBlockConfirmations } from "./validateBlockConfirmations";
import { validateDecodedArgs } from "./validateDecodedArgs";
import { validateValidatorLib } from "./validateValidatorLib";

async function fetchReport(
	runtime: Runtime<GlobalConfig>,
	item: DecodedArgs["batch"][number],
): Promise<{ report: ReturnType<Report["x_generatedCodeOnly_unwrap"]>; messageId: string }> {
	const routerAddress = ChainsManager.getOptionsBySelector(item.srcChainSelector).deployments
		.router;
	if (!routerAddress) {
		throw new DomainError(ErrorCode.NO_CHAIN_DATA, "Router deployment not found");
	}

	runtime.log(`Got routerAddress=${routerAddress}`);
	if (!routerAddress) throw new Error("Router");
	const publicClient = PublicClient.create(runtime, item.srcChainSelector);

	const [log, currentBlockNumber] = await Promise.all([
		fetchLogByMessageId(
			runtime,
			publicClient,
			routerAddress,
			item.messageId,
			BigInt(Number(item.blockNumber)),
		),
		publicClient.getBlockNumber(),
	]);
	const parsedLog = parseMessageSentLog(log);

	runtime.log(`Got ConceroMessageSent Log`);
	validateBlockConfirmations(parsedLog.blockNumber, parsedLog.receipt, currentBlockNumber);
	validateValidatorLib(parsedLog.receipt.srcChainSelector, parsedLog.data.validatorLibs);

	if (!log || !log?.data) {
		runtime.log(`Log where messageId=${item.messageId} not found`);
	}

	return {
		messageId: item.messageId,
		report: runtime
			.report({
				encoderName: "evm",
				encodedPayload: Buffer.from(
					keccak256(parsedLog.rawMessageReceipt, "bytes"),
				).toString("base64"),
				signingAlgo: "ecdsa",
				hashingAlgo: "keccak256",
			})
			.result()
			.x_generatedCodeOnly_unwrap(),
	};
}

// pipeline stages for each validation request
export async function pipeline(runtime: Runtime<GlobalConfig>, payload: HTTPPayload) {
	try {
		ChainsManager.enrichOptions(runtime);
		ChainsManager.validateOptions(runtime);

		const args = decodeArgs(payload);
		validateDecodedArgs(args);
		runtime.log(`Decoded args: ${JSON.stringify(args)}`);

		const fetchReportPromises = args.batch.map(item => fetchReport(runtime, item));
		const reports = await Promise.all(fetchReportPromises);
		const response = buildResponseFromBatches(reports);
		sendReportsToRelayer(runtime, response);

		return "success";
	} catch (error) {
		runtime.log(
			`Pipeline failed with error ${error instanceof Error ? `${error.message} ${error.stack}` : error?.toString()}`,
		);
	}
}
