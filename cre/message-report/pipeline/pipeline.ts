import { HTTPPayload, Report, Runtime } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { DecodedArgs, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { ChainsManager, PublicClient } from "../systems";
import { buildResponseFromBatches } from "./buildResponseFromBatches";
import { decodeArgs } from "./decodeArgs";
import { fetchLogByMessageId } from "./fetchLogByMessageId";
import { sendReportsToRelayer } from "./sendReportsToRelayer";
import { validateBlockConfirmations } from "./validateBlockConfirmations";
import { validateDecodedArgs } from "./validateDecodedArgs";
import { validateRelayerLib } from "./validateRelayerLib";

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
	runtime.log(`Got ConceroMessageSent Log`);

	validateBlockConfirmations(log, currentBlockNumber);
	validateRelayerLib(log);

	// TODO: Validate which validator library is specified in the event. If it is not a CRE validator library, do not create a report
	if (!log || !log?.data) {
		runtime.log(`Log where messageId=${item.messageId} not found`);
	}

	return {
		messageId: item.messageId,
		report: runtime
			.report({
				encoderName: "evm",
				encodedPayload: sha256(Buffer.from(JSON.stringify(log.data))),
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
