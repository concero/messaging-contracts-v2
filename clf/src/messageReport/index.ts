import { ChainType, ReportType } from "../common/enums";
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

	const [log, operators] = await Promise.all([
		fetchConceroMessage(
			publicClient,
			conceroRouters[Number(msgConfig.srcChainSelector)],
			args.messageId,
			BigInt(args.srcChainData.blockNumber),
		),
		getAllowedOperators(ChainType.EVM, args.messageId),
	]);

	const {
		version: messageVersion,
		shouldFinaliseSrc,
		dstChainSelector,
		dstChainData,
		sender,
		message,
	} = decodeConceroMessageLog(log);

	verifyMessageHash(message, args.messageHashSum);

	const allowedOperators = pick(operators, 1);

	const messageReportResult: MessageReportResult = {
		reportVersion: CONFIG.REPORT_VERSION,
		reportType: ReportType.MESSAGE,
		requester: args.operatorAddress,
		messageVersion,
		messageId: args.messageId,
		messageHashSum: args.messageHashSum,
		sender,
		srcChainSelector: msgConfig.srcChainSelector,
		dstChainSelector,
		dstChainData,
		shouldFinaliseSrc,
		allowedOperators,
	};

	return packResult(
		messageReportResult,
		packReportConfig(ReportType.MESSAGE, CONFIG.REPORT_VERSION, args.operatorAddress),
	);
}
