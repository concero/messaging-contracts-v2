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
import { decodeInputs } from "./utils/validateInputs";
import { verifyMessageHash } from "./utils/verifyMessageHash";

export async function main() {
	const args = decodeInputs(bytesArgs);
	const msgConfig = args.internalMessageConfig;
	const publicClient = getPublicClient(msgConfig.srcChainSelector.toString());

	const log = await fetchConceroMessage(
		publicClient,
		conceroRouters[Number(msgConfig.srcChainSelector)],
		args.messageId,
		BigInt(args.srcChainData.blockNumber),
	);

	const {
		messageId,
		internalMessageConfig: messageConfigFromLog,
		dstChainData: dstChainDataFromLog,
		message: messageFromLog,
	} = decodeConceroMessageLog(log);

	verifyMessageHash(messageFromLog, args.messageHashSum);

	const operators = await getAllowedOperators(ChainType.EVM, args.messageId);
	const allowedOperators = pick(operators, 1);

	const messageReportResult: MessageReportResult = {
		version: CONFIG.REPORT_VERSION,
		reportType: ReportType.MESSAGE,
		requester: args.operatorAddress,
		internalMessageConfig: messageConfigFromLog,
		messageId: args.messageId,
		messageHashSum: args.messageHashSum,
		dstChainData: dstChainDataFromLog,
		allowedOperators,
	};

	const packedReportConfig = packReportConfig(ReportType.MESSAGE, CONFIG.REPORT_VERSION, args.operatorAddress);

	return packResult(messageReportResult, packedReportConfig);
}
