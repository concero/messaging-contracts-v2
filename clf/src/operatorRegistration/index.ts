import { ChainType, ReportType } from "../common/enums";
import { CustomErrorHandler, handleError } from "../common/errorHandler";
import { ErrorType } from "../common/errorType";
import { packReportConfig } from "../common/packReportConfig";
import { CONFIG } from "./constants/config";
import { OperatorRegistrationResult } from "./types";
import { packResult } from "./utils/packResult";
import { decodeInputs, validateDecodedArgs } from "./utils/validateInputs";

export async function main(bytesArgs: string[]) {
	try {
		const decodedArgs = decodeInputs(bytesArgs);
		const validatedArgs = validateDecodedArgs(decodedArgs);

		if (args.chainTypes.includes(ChainType.EVM) && args.operatorAddresses[0] !== args.requester) {
			handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
		}

		// await verifyOperatorStake(args.requester);

		const registrationReportResult: OperatorRegistrationResult = {
			version: CONFIG.REPORT_VERSION,
			reportType: ReportType.OPERATOR_REGISTRATION,
			requester: args.requester,
			actions: args.actions,
			chainTypes: args.chainTypes,
			operatorAddresses: args.operatorAddresses,
		};

		const reportConfig = packReportConfig(
			ReportType.OPERATOR_REGISTRATION,
			CONFIG.REPORT_VERSION,
			args.operatorAddresses,
		);
		return packResult(registrationReportResult, reportConfig);
	} catch (error) {
		if (error instanceof CustomErrorHandler) {
			throw error;
		} else {
			handleError(ErrorType.UNKNOWN_ERROR);
		}
	}
}
