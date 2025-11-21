import { HTTPPayload, Report, Runtime } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { DecodedArgs, GlobalConfig } from "../helpers";
import { ChainsManager, PublicClient } from "../systems";
import { DeploymentsManager } from "../systems/deploymentsManager";
import { buildResponseFromBatches } from "./buildResponseFromBatches";
import { decodeArgs } from "./decodeArgs";
import { fetchLogByMessageId } from "./fetchLogByMessageId";
import { sendReportsToRelayer } from "./sendReportsToRelayer";
import { validateDecodedArgs } from "./validateDecodedArgs";

async function fetchReport(
	runtime: Runtime<GlobalConfig>,
	item: DecodedArgs["batch"][number],
): Promise<{ report: ReturnType<Report["x_generatedCodeOnly_unwrap"]>; messageId: string }> {
	const routerAddress = DeploymentsManager.getDeploymentByChainSelector(item.srcChainSelector);
	runtime.log(`Got routerAddress=${routerAddress}`);
	const publicClient = PublicClient.create(runtime, item.srcChainSelector);

	const log = await fetchLogByMessageId(
		runtime,
		publicClient,
		routerAddress,
		item.messageId,
		BigInt(Number(item.blockNumber)),
	);
	runtime.log(`Got ConceroMessageSent Log`);

	// TODO: In order to support the wait for a certain
	//  number of block confirmations, we need to make a parallel request for the current block number and see if there are enough block confirmations.

	// TODO: Validate which validator library is specified in the event. If it is not a CRE validator library, do not create a report
	if (!log || !log?.data) {
		runtime.log(`Log where messageId=${item.messageId} not found`);
	}

	return {
		messageId: item.messageId,
		report: runtime
			.report({
				encoderName: "evm",
				encodedPayload: sha256(log.data),
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
		ChainsManager.enrichOptions();
		ChainsManager.validateOptions(runtime);
		DeploymentsManager.enrichDeployments(runtime);

		const args = decodeArgs(payload);
		validateDecodedArgs(args);
		runtime.log(`Decoded args: ${JSON.stringify(args)}`);

		const fetchReportPromises = args.batch.map(item => fetchReport(runtime, item));
		const reports = await Promise.all(fetchReportPromises);
		const response = buildResponseFromBatches(reports);
		sendReportsToRelayer(runtime, response);
	} catch (error) {
		runtime.log(
			`Pipeline failed with error ${error instanceof Error ? `${error.message} ${error.stack}` : error?.toString()}`,
		);
	}
}
