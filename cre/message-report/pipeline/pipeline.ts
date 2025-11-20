import { HTTPPayload, Report, Runtime } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { DecodedArgs, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { ChainsManager, PublicClient } from "../systems";
import { DeploymentsManager } from "../systems/deploymentsManager";
import { decodeArgs } from "./decodeArgs";
import { fetchLogByMessageId } from "./fetchLogByMessageId";
import { sendReportsToRelayer } from "./sendReportsToRelayer";
import { validateDecodedArgs } from "./validateDecodedArgs";

async function fetchReport(
	runtime: Runtime<GlobalConfig>,
	item: DecodedArgs["batch"][number],
): Promise<Report> {
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
		runtime.log(`No log found for messageId=${item.messageId}`);
		// TODO: We are batching, so we should not throw an error if we did not find 1 event from the batch.
		throw new DomainError(ErrorCode.EVENT_NOT_FOUND);
	}

	return runtime
		.report({
			encoderName: "evm",
			encodedPayload: sha256(log.data),
			signingAlgo: "ecdsa",
			hashingAlgo: "keccak256",
		})
		.result();
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
		sendReportsToRelayer(runtime, reports);

		// @todo: check that should respond with batches
		return sha256(payload.input);
	} catch (error) {
		runtime.log(
			`Pipeline failed with error ${error instanceof Error ? `${error.message} ${error.stack}` : error?.toString()}`,
		);
		return "0x0";
	}
}
