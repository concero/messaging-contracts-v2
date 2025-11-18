import {HTTPPayload, Report, Runtime} from "@chainlink/cre-sdk";
import {sha256} from "viem";

import {DecodedArgs, DomainError, ErrorCode, GlobalConfig} from "../helpers";
import {ChainsManager, PublicClient} from "../systems";
import {DeploymentsManager} from "../systems/deploymentsManager";
import {decodeArgs} from "./decodeArgs";
import {fetchLogByMessageId} from "./fetchLogByMessageId";
import {sendReportsToRelayer,} from "./sendReportsToRelayer";
import {validateDecodedArgs} from "./validateDecodedArgs";

async function fetchReport (runtime: Runtime<GlobalConfig>, batch: DecodedArgs['batches'][number]): Promise<Report> {
    const routerAddress = DeploymentsManager.getDeploymentByChainSelector(
        batch.srcChainSelector,
    );
    runtime.log(`Got routerAddress=${routerAddress}`);
    const publicClient = PublicClient.create(runtime, batch.srcChainSelector);

    const log = await fetchLogByMessageId(
        runtime,
        publicClient,
        routerAddress,
        batch.messageId,
        BigInt(Number(batch.blockNumber)),
    );
    runtime.log(`Got ConceroMessageSent Log`);

    if (!log || !log?.data) {
        runtime.log(`No log found for messageId=${batch.messageId}`);
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

        const fetchReportPromises = args.batches.map(batch => fetchReport(runtime, batch))
        const reports = await Promise.all(fetchReportPromises)
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
