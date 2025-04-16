import { ChainType, ResultType } from "../common/enums";
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
			payloadVersion: CONFIG.REPORT_VERSION,
			resultType: ResultType.OPERATOR_REGISTRATION,
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
