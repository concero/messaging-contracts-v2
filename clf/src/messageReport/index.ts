import { packResult } from "./utils/packResult";
import { ChainType, ReportType } from "../common/enums";
import { getPublicClient } from "../common/viemClient";
import { pick } from "./utils/utils";
import { getAllowedOperators } from "./utils/getAllowedOperators";
import { conceroRouters } from "./constants/conceroRouters";
import { CONFIG } from "./constants/config";
import { verifyMessageHash } from "./utils/verifyMessageHash";
import { decodeInputs, validateDecodedArgs, validateInputs } from "./utils/validateInputs";
import { decodeConceroMessageLog, decodeEvmSrcChainData } from "./utils/decoders";
import { fetchConceroMessage } from "./utils/fetchConceroMessage";
import { CustomErrorHandler, handleError } from "../common/errorHandler";
import { ErrorType } from "../common/errorType";
import { MessageReportResult } from "./types";

export async function main(bytesArgs: string[]) {
    try {
        const args = decodeInputs(bytesArgs);
        validateDecodedArgs(args);
        const msgConfig = args.internalMessageConfig;

        const { srcChainSelector } = msgConfig;
        const publicClient = getPublicClient(Number(msgConfig.srcChainSelector));

        const log = await fetchConceroMessage(
            publicClient,
            conceroRouters[Number(msgConfig.srcChainSelector)],
            args.messageId,
            BigInt(args.srcChainData.blockNumber),
        );
        const {
            messageConfig: messageConfigFromLog,
            dstChainData: dstChainDataFromLog,
            message: messageFromLog,
        } = decodeConceroMessageLog(log.data);

        const recomputedMessageHashSum = await verifyMessageHash(
            args.messageId,
            messageConfigFromLog.toString(),
            dstChainDataFromLog,
            messageFromLog,
            args.messageHashSum,
        );

        const operators = await getAllowedOperators(publicClient, ChainType.EVM, args.messageId);
        const allowedOperators = pick(operators, 3);

        const messageReportResult: MessageReportResult = {
            version: CONFIG.REPORT_VERSION,
            reportType: ReportType.MESSAGE,
            requester: args.operatorAddress,
            internalMessageConfig: messageConfigFromLog.toString(),
            messageId: args.messageId,
            messageHashSum: recomputedMessageHashSum,
            dstChainData: dstChainDataFromLog,
            allowedOperators,
        };

        return packResult(messageReportResult);
    } catch (error) {
        console.log(error);
        if (error instanceof CustomErrorHandler) {
            throw error;
        } else {
            handleError(ErrorType.UNKNOWN_ERROR);
        }
    }
}
