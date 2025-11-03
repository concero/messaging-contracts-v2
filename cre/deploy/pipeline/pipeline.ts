import { HTTPPayload, Runtime } from "@chainlink/cre-sdk";

import { conceroRouters, CONFIG } from "../constants";
import { getPublicClient } from "../client";
import { GlobalContext, MessageReportResult, ResultType } from "../types";
import { decodeArgs } from "./decodeArgs";
import { validateDecodedArgs } from "./validateDecodedArgs";
import { fetchLogByMessageId } from "./fetchLogByMessageId";
import { decodeMessageLog } from "./decodeLog";
import { verifyMessageHash } from "./verifyMessageHash";
import { packResult } from "./packResult";

// pipeline stages for each validation request
export async function pipeline(runtime: Runtime<GlobalContext>, payload: HTTPPayload) {
    try {
        const args = decodeArgs(payload);
        validateDecodedArgs(args);

        const publicClient = getPublicClient(args.srcChainSelector.toString());

        const log = await fetchLogByMessageId(
            publicClient,
            conceroRouters[Number(args.srcChainSelector)],
            args.messageId,
            BigInt(args.srcChainData.blockNumber),
        );
        const { dstChainSelector, dstChainData, sender, message } = decodeMessageLog(log);
        verifyMessageHash(message, args.messageHashSum);

        const rawReport: MessageReportResult = {
            payloadVersion: CONFIG.PAYLOAD_VERSION,
            resultType: ResultType.MESSAGE,
            requester: args.operatorAddress,
            messageId: args.messageId,
            messageHashSum: args.messageHashSum,
            messageSender: sender,
            srcChainSelector: args.srcChainSelector,
            dstChainSelector: Number(dstChainSelector),
            srcBlockNumber: log.blockNumber as bigint,
            dstChainData,
            allowedOperators: [],
        };
        const packedReport = packResult(rawReport);

        const report = runtime.report({
            encoderName: 'evm',
            encodedPayload: String(packedReport),
            signingAlgo: 'ecdsa',
            hashingAlgo: 'keccak256'
        }).result()

        return log?.transactionHash?.toString() || '0x0a000';

        // @todo: add sendMessage
        /*const httpClient = new cre.capabilities.HTTPClient()
        const sentRequest = httpClient.sendRequest(
            runtime,
            (sendRequester) => {sendRequester.}
        )(); */
    } catch (error) {
        runtime.log(`Pipeline failed with error ${error?.toString()}`);
        return "0x0a000";
    }
}
