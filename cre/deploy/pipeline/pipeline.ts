import {HTTPPayload, Runtime} from "@chainlink/cre-sdk";
import {sha256} from "viem";

import {GlobalContext, Utility} from "../helpers";
import {ChainsManager, PublicClient} from "../systems";
import {decodeArgs} from "./decodeArgs";
import {validateDecodedArgs} from "./validateDecodedArgs";
import {fetchLogByMessageId} from "./fetchLogByMessageId";
import {sendReportToRelayer} from "./sendReportToRelayer";
import {DeploymentsManager} from "../systems/deploymentsManager";


// pipeline stages for each validation request
export async function pipeline(runtime: Runtime<GlobalContext>, payload: HTTPPayload) {
    try {
        ChainsManager.enrichOptions();
        ChainsManager.validateOptions(runtime);
        DeploymentsManager.enrichDeployments(runtime);

        const args = decodeArgs(payload);
        validateDecodedArgs(args)
        runtime.log(`Decoded args: ${JSON.stringify(args)}`);

        const routerAddress = DeploymentsManager.getDeploymentByChainSelector(args.srcChainSelector);
        runtime.log(`Got routerAddress=${routerAddress}`);
    
        const publicClient = PublicClient.create(runtime, args.srcChainSelector);
        runtime.log(`Got publicClient: ${JSON.stringify(publicClient)}`);

        const log = await fetchLogByMessageId(runtime,
            publicClient,
            routerAddress,
            args.messageId,
            BigInt(Number(args.blockNumber))
        );
        runtime.log(`Got Log: ${Utility.safeJSONStringify(log)}`);

        if (!log || !log?.data) {
            runtime.log(`❌ No log found for messageId=${args.messageId}`);
            return "0x0";
        }

        const report = runtime
            .report({
                encoderName: 'evm',
                encodedPayload: sha256(log.data),
                signingAlgo: 'ecdsa',
                hashingAlgo: 'keccak256',
            })
            .result();

        sendReportToRelayer(runtime, report);

        return sha256(log.data);
    } catch (error) {
        runtime.log(`Pipeline failed with error ${error instanceof Error ? `${error.message} ${error.stack}` : error?.toString()}`);
        return "0x0";
    }
}
