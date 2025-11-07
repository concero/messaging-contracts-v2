import { HTTPPayload, Runtime } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { conceroRouters } from "../constants";
import { getPublicClient, validateConfigs } from "../client";
import { GlobalContext } from "../types";
import { decodeArgs } from "./decodeArgs";
import { validateDecodedArgs } from "./validateDecodedArgs";
import { fetchLogByMessageId } from "./fetchLogByMessageId";
import { sendReportToRelayer } from "./sendReportToRelayer";
import { Utility } from "../utility";


// pipeline stages for each validation request
export async function pipeline(runtime: Runtime<GlobalContext>, payload: HTTPPayload) {
    try {
        validateConfigs(runtime);

        const args = decodeArgs(payload);
        validateDecodedArgs(args)
        runtime.log(`Decoded args: ${JSON.stringify(args)}`);

        if (!conceroRouters) {
            runtime.log("⚠️ conceroRouters is undefined");
            return "0x0";
        }

        const routerAddress = conceroRouters[args.srcChainSelector] || '0x0';
        runtime.log(`Got routerAddress=${routerAddress}`);

        if (routerAddress === '0x0') {
            runtime.log(`⚠️ No known router for srcChainSelector=${args.srcChainSelector}`);
            return "0x0";
        }

        const publicClient = getPublicClient(runtime, args.srcChainSelector);
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
