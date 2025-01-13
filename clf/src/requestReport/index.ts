import { keccak256, encodeAbiParameters } from "viem";
import { packResult } from "./packResult";
import { ChainType, ClientMessageRequest, conceroRouters, CONFIG, ErrorType, ReportType } from "./constants";
import { getPublicClient } from "./viemClient";
import { decodeInternalMessageConfig, validateInternalMessageConfig } from "./messageConfig";
import { decodeConceroMessageLog, fetchConceroMessage, pick } from "./utils";
import { getAllowedOperators } from "./getAllowedOperators";

export async function main(bytesArgs: string[]) {
    if (bytesArgs.length < 6) throw new Error(ErrorType.INVALID_INPUT);
    const [_, messageConfig, messageId, messageHashSum, srcBlockNumber, relayerAddress] = bytesArgs;

    const decodedInternalMessageConfig = decodeInternalMessageConfig(BigInt(messageConfig));
    validateInternalMessageConfig(decodedInternalMessageConfig);

    const {
        version,
        srcChainSelector,
        dstChainSelector,
        minSrcConfirmations,
        minDstConfirmations,
        relayerConfig,
        isCallbackable,
    } = decodedInternalMessageConfig;

    const client = getPublicClient(srcChainSelector);

    // let latestBlockNumber = BigInt(await client.getBlockNumber());
    // Fetch the log by messageId
    // const srcBlockNumber = await getLogByMessageId(
    //     client,
    //     conceroRouters[srcChainSelector],
    //     messageId,
    //     latestBlockNumber,
    // ).then(log => BigInt(log.blockNumber));

    // // // Wait for the required confirmations
    // // while (latestBlockNumber - srcBlockNumber < confirmations) {
    // //     latestBlockNumber = BigInt(await client.getBlockNumber());
    // //     await sleep(3000);
    // // }
    // // Fetch the log again after confirmations

    const log = await fetchConceroMessage(client, conceroRouters[srcChainSelector], messageId, BigInt(srcBlockNumber));
    const parsedMessage = decodeConceroMessageLog(log.data);
    const { messageConfig: messageConfigFromLog, dstChainData, message } = parsedMessage;

    const messageBytes = encodeAbiParameters(
        ["bytes32", ClientMessageRequest],
        [
            messageId,
            {
                messageConfig: BigInt(messageConfigFromLog),
                dstChainData,
                message: keccak256(message),
            },
        ],
    );

    const recomputedMessageHashSum = keccak256(messageBytes);
    if (recomputedMessageHashSum !== messageHashSum) throw new Error(ErrorType.INVALID_HASHSUM);

    const operators = await getAllowedOperators(client, ChainType.EVM, messageId);
    const allowedOperators = pick(operators, 3);

    const messageReportResult = {
        version: CONFIG.REPORT_VERSION,
        reportType: ReportType.MESSAGE,
        operator: relayerAddress,
        internalMessageConfig: messageConfigFromLog,
        messageId,
        messageHashSum: recomputedMessageHashSum,
        allowedOperators,
    };

    const encodedResult = encodeAbiParameters(
        [
            "uint8", // version
            "uint8", // reportType
            "address", // operator
            "bytes32", // internalMessageConfig
            "bytes32", // messageId
            "bytes32", // messageHashSum
            "bytes[]", // allowedOperators
        ],
        [
            messageReportResult.version,
            messageReportResult.reportType,
            messageReportResult.operator,
            messageReportResult.internalMessageConfig,
            messageReportResult.messageId,
            messageReportResult.messageHashSum,
            messageReportResult.allowedOperators,
        ],
    );

    return packResult(messageId, recomputedMessageHashSum, BigInt(srcChainSelector), BigInt(srcBlockNumber));
}
