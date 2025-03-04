import { ChainType, ReportType } from "../common/enums";
import { CustomErrorHandler, handleError } from "../common/errorHandler";
import { ErrorType } from "../common/errorType";
import { packReportConfig } from "../common/packReportConfig";
import { getPublicClient } from "../common/viemClient";
import { conceroRouters } from "./constants/conceroRouters";
import { CONFIG } from "./constants/config";
import { MessageReportResult } from "./types";
import { decodeConceroMessageLog } from "./utils/decoders";
import { fetchConceroMessage } from "./utils/fetchConceroMessage";
import { getAllowedOperators } from "./utils/getAllowedOperators";
import { packResult } from "./utils/packResult";
import { pick } from "./utils/utils";
import { decodeInputs, validateDecodedArgs } from "./utils/validateInputs";
import { verifyMessageHash } from "./utils/verifyMessageHash";

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
			messageId: messageIdFromLog,
			internalMessageConfig: messageConfigFromLog,
			dstChainData: dstChainDataFromLog,
			message: messageFromLog,
		} = decodeConceroMessageLog(log.data);

		if (messageIdFromLog !== args.messageId) {
			handleError(ErrorType.INVALID_MESSAGE_ID);
		}

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

		const packedReportConfig = packReportConfig(
			ReportType.MESSAGE,
			CONFIG.REPORT_VERSION,
			args.operatorAddress,
		);

		return packResult(messageReportResult, packedReportConfig);
	} catch (error) {
		console.log(error);
		if (error instanceof CustomErrorHandler) {
			throw error;
		} else {
			handleError(ErrorType.UNKNOWN_ERROR);
		}
	}
}
