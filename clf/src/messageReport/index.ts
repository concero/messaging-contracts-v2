import { packResult } from "./utils/packResult";
import { ChainType, ReportType } from "./enums";
import { getPublicClient } from "./utils/viemClient";
import { decodeInternalMessageConfig, validateInternalMessageConfig } from "./utils/messageConfig";
import { pick } from "./utils/utils";
import { getAllowedOperators } from "./utils/getAllowedOperators";
import { conceroRouters } from "./constants/conceroRouters";
import { CONFIG } from "./constants/config";
import { verifyMessageHash } from "./utils/verifyMessageHash";
import { validateInputs } from "./utils/validateInputs";
import { decodeConceroMessageLog, decodeEvmSrcChainData } from "./utils/decoders";
import { fetchConceroMessage } from "./utils/fetchConceroMessage";
import { CustomErrorHandler, handleError } from "./utils/errorHandler";
import { ErrorType } from "./constants/errorTypes";

export async function main(bytesArgs: string[]) {
    try {
        const args = validateInputs(bytesArgs);

        const decodedInternalMessageConfig = decodeInternalMessageConfig(BigInt(args.internalMessageConfig));
        validateInternalMessageConfig(decodedInternalMessageConfig);

        const { srcChainSelector } = decodedInternalMessageConfig;
        const publicClient = getPublicClient(srcChainSelector);

        const evmSrcChainData = decodeEvmSrcChainData(args.srcChainData);
        const log = await fetchConceroMessage(
            publicClient,
            conceroRouters[srcChainSelector],
            args.messageId,
            BigInt(evmSrcChainData.blockNumber),
        );
        const {
            messageConfig: messageConfigFromLog,
            dstChainData: dstChainDataFromLog,
            message: messageFromLog,
        } = decodeConceroMessageLog(log.data);

        const recomputedMessageHashSum = await verifyMessageHash(
            args.messageId,
            messageConfigFromLog,
            dstChainDataFromLog,
            messageFromLog,
            args.messageHashSum,
        );

        const operators = await getAllowedOperators(publicClient, ChainType.EVM, args.messageId);
        const allowedOperators = pick(operators, 3);

        const messageReportResult = {
            version: CONFIG.REPORT_VERSION,
            reportType: ReportType.MESSAGE,
            operator: args.operatorAddress,
            internalMessageConfig: messageConfigFromLog,
            messageId: args.messageId,
            messageHashSum: recomputedMessageHashSum,
            dstChainData: dstChainDataFromLog,
            allowedOperators,
        };

        return packResult(messageReportResult);
    } catch (error) {
        if (error instanceof CustomErrorHandler) {
            throw error;
        } else {
            handleError(ErrorType.UNKNOWN_ERROR); // Optionally rethrow or handle the error as needed
        }
    }
}
