import { ChainType, ReportType } from "../common/enums";
import { CustomErrorHandler, handleError } from "../common/errorHandler";
import { ErrorType } from "../common/errorType";
import { CONFIG } from "./constants/config";
import { OperatorRegistrationResult } from "./types";
import { packResult } from "./utils/packResult";
import { decodeInputs, validateDecodedArgs } from "./utils/validateInputs";
import { verifyOperatorStake } from "./utils/verifyOperatorStake";

export async function main(bytesArgs: string[]) {
	try {
		const decodedArgs = decodeInputs(bytesArgs);
		const validatedArgs = validateDecodedArgs(decodedArgs);

		if (
			args.chainTypes.includes(ChainType.EVM) &&
			args.operatorAddresses[0] !== args.requester
		) {
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

		return packResult(registrationReportResult);
	} catch (error) {
		if (error instanceof CustomErrorHandler) {
			throw error;
		} else {
			handleError(ErrorType.UNKNOWN_ERROR);
		}
	}
}
