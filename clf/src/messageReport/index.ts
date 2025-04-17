import { ChainType, ResultType } from "../common/enums";
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
	const publicClient = getPublicClient(args.srcChainSelector.toString());

	const [log, operators] = await Promise.all([
		fetchConceroMessage(
			publicClient,
			conceroRouters[Number(args.srcChainSelector)],
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
		payloadVersion: CONFIG.PAYLOAD_VERSION,
		resultType: ResultType.MESSAGE,
		requester: args.operatorAddress,
		messageId: args.messageId,
		messageHashSum: args.messageHashSum,
		sender,
		srcChainSelector: args.srcChainSelector,
		dstChainSelector,
		dstChainData,
		allowedOperators,
	};

	return packResult(messageReportResult);
}
