import { validateInputs } from "./utils/validateInputs";
import { verifyOperatorStake } from "./utils/verifyOperatorStake";
import { packResult } from "./utils/packResult";
import { ChainType, ReportType } from "../common/enums";
import { CONFIG } from "./constants/config";
import { handleError, CustomErrorHandler } from "../common/errorHandler";
import { ErrorType } from "./constants/errorTypes";

export async function main(bytesArgs: string[]) {
    try {
        const args = validateInputs(bytesArgs);

        if (args.chainTypes.includes(ChainType.EVM) && args.operatorAddresses[0] !== args.operatorAddress) {
            handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
        }

        await verifyOperatorStake(args.operatorAddress);

        const registrationReportResult = {
            version: CONFIG.REPORT_VERSION,
            reportType: ReportType.OPERATOR_REGISTRATION,
            operator: args.operatorAddress,
            chainTypes: args.chainTypes,
            operatorAddresses: args.operatorAddresses,
        };

        return packResult(registrationReportResult);
    } catch (error) {
        if (error instanceof CustomErrorHandler) {
            throw error;
        } else {
            handleError(ErrorType.UNKNOWN_ERROR); // Optionally rethrow or handle the error as needed
        }
    }
}
