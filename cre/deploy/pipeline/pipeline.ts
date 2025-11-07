import {consensusIdenticalAggregation, cre, HTTPPayload, ok, Runtime} from "@chainlink/cre-sdk";

import {conceroRouters, CONFIG} from "../constants";
import {getPublicClient} from "../client";
import {GlobalContext, MessageReportResult, ResultType} from "../types";
import {decodeArgs} from "./decodeArgs";
import {validateDecodedArgs} from "./validateDecodedArgs";
import {fetchLogByMessageId} from "./fetchLogByMessageId";
import {decodeMessageLog} from "./decodeLog";
import {verifyMessageHash} from "./verifyMessageHash";
import {packResult} from "./packResult";
import {HTTPSendRequester} from "@chainlink/cre-sdk/dist/sdk/cre";
import {sha256} from "viem";

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

        const report = runtime
          .report({
            encoderName: 'evm',
            encodedPayload: String(packedReport),
            signingAlgo: 'ecdsa',
            hashingAlgo: 'keccak256'
          })
          .result()
          .x_generatedCodeOnly_unwrap();

        console.log(JSON.stringify(report, null, 2));


        const postData = (sendRequester: HTTPSendRequester, config: GlobalContext): { statusCode: number } => {
            const dataToSend = {
                rawReport: report.rawReport,
                signs: report.sigs,
                reportContext: report.reportContext
            }
            const bodyBytes = new TextEncoder().encode(JSON.stringify(dataToSend))

            const body = Buffer.from(bodyBytes).toString("base64")

            const req = {
                url: "https://webhook.site/1c3accdb-1b88-4539-8e35-62ac6efb1e11",
                method: "POST" as const,
                body,
                headers: {
                    "Content-Type": "application/json",
                }
            }

            const resp = sendRequester.sendRequest(req).result()

            if (!ok(resp)) {
                throw new Error(`HTTP request failed with status: ${resp.statusCode}`)
            }

            return { statusCode: resp.statusCode }
        }

        const httpClient = new cre.capabilities.HTTPClient()
        const result = httpClient
            .sendRequest(
                runtime,
                postData,
                consensusIdenticalAggregation()
            )(runtime.config) // Call with config
            .result()
        console.log(result)

        return sha256(log.transactionHash || '0x00')
    } catch (error) {
        runtime.log(`Pipeline failed with error ${error?.toString()}`);
        return "0x0a000";
    }
}
