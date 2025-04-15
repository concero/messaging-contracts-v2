import { ChainType, ReportType } from "../common/enums";
import { handleError } from "../common/errorHandler";
import { ErrorType } from "../common/errorType";
import { packReportConfig } from "../common/packReportConfig";
import { CONFIG } from "./constants/config";
import { OperatorRegistrationResult } from "./types";
import { packResult } from "./utils/packResult";
import { decodeInputs, validateDecodedArgs } from "./utils/validateInputs";

export async function main() {
	const decodedArgs = decodeInputs(bytesArgs);
	validateDecodedArgs(decodedArgs);

	if (decodedArgs.chainTypes.includes(ChainType.EVM) && decodedArgs.operatorAddresses[0] !== decodedArgs.requester) {
		handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
	}

	// await verifyOperatorStake(decodedArgs.requester);

	const registrationReportResult: OperatorRegistrationResult = {
		version: CONFIG.REPORT_VERSION,
		reportType: ReportType.OPERATOR_REGISTRATION,
		requester: decodedArgs.requester,
		actions: decodedArgs.actions,
		chainTypes: decodedArgs.chainTypes,
		operatorAddresses: decodedArgs.operatorAddresses,
	};

	const reportConfig = packReportConfig(
		ReportType.OPERATOR_REGISTRATION,
		CONFIG.REPORT_VERSION,
		decodedArgs.operatorAddresses,
	);
	return packResult(registrationReportResult, reportConfig);
}
