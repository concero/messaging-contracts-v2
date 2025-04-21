import { ChainType, ResultType } from "../common/enums";
import { handleError } from "../common/errorHandler";
import { ErrorType } from "../common/errorType";
import { CONFIG } from "./constants/config";
import { OperatorRegistrationResult } from "./types";
import { packResult } from "./utils/packResult";
import { decodeInputs, validateDecodedArgs } from "./utils/validateInputs";

export async function main() {
	const decodedArgs = decodeInputs(bytesArgs);
	validateDecodedArgs(decodedArgs);

	if (
		decodedArgs.chainTypes.includes(ChainType.EVM) &&
		decodedArgs.operatorAddresses[0].toLocaleLowerCase() !== decodedArgs.requester.toLocaleLowerCase()
	) {
		handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
	}

	// await verifyOperatorStake(decodedArgs.requester);

	const registrationReportResult: OperatorRegistrationResult = {
		payloadVersion: CONFIG.REPORT_VERSION,
		resultType: ResultType.OPERATOR_REGISTRATION,
		requester: decodedArgs.requester,
		actions: decodedArgs.actions,
		chainTypes: decodedArgs.chainTypes,
		operatorAddresses: decodedArgs.operatorAddresses,
	};

	return packResult(registrationReportResult);
}
