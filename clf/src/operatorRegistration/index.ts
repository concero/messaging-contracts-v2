import { decodeInputs, validateDecodedArgs } from "./utils/validateInputs";
import { verifyOperatorStake } from "./utils/verifyOperatorStake";
import { packResult } from "./utils/packResult";
import { ChainType, ReportType } from "../common/enums";
import { CONFIG } from "./constants/config";
import { handleError, CustomErrorHandler } from "../common/errorHandler";
import { ErrorType } from "../common/errorType";
import { OperatorRegistrationResult } from "./types";

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

        return packResult(registrationReportResult);
    } catch (error) {
        if (error instanceof CustomErrorHandler) {
            throw error;
        } else {
            handleError(ErrorType.UNKNOWN_ERROR);
        }
    }
}
