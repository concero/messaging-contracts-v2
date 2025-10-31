import { conceroRouters, CONFIG } from "./constants";
import { getPublicClient, Fetcher } from "./client";
import { MessagePipeline } from "./messageReport";
import { ChainType, Log, ResultType } from "./types";
import { getAllowedOperators } from "./messageReport/getAllowedOperators";
import { pick } from "./messageReport/utils";
import { MessageReportResult } from "./messageReport/types";


export async function main() {
    const args = MessagePipeline.decodeArgs(bytesArgs);
    const publicClient = getPublicClient(args.srcChainSelector.toString());

    const [log, operators] = await Promise.all([
        Fetcher.fetchConceroMessage(
            publicClient,
            conceroRouters[Number(args.srcChainSelector)],
            args.messageId,
            BigInt(args.srcChainData.blockNumber),
        ),
        getAllowedOperators(ChainType.EVM, args.messageId),
    ]);

    const { dstChainSelector, dstChainData, sender, message } = MessagePipeline.decodeMessageLog(log);

    MessagePipeline.verifyMessageHash(message, args.messageHashSum);

    const allowedOperators = pick(operators, 1);
    const messageReportResult: MessageReportResult = {
        payloadVersion: CONFIG.PAYLOAD_VERSION,
        resultType: ResultType.MESSAGE,
        requester: args.operatorAddress,
        messageId: args.messageId,
        messageHashSum: args.messageHashSum,
        messageSender: sender,
        srcChainSelector: args.srcChainSelector,
        dstChainSelector,
        srcBlockNumber: log.blockNumber,
        dstChainData,
        allowedOperators,
    };

    return MessagePipeline.packResult(messageReportResult);
}
