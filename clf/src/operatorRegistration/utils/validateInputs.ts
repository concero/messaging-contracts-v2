import { OperatorRegistrationArgs } from "../types";
import { ErrorType } from "../constants/errorTypes";
import { handleError } from "../../common/errorHandler";

export function validateInputs(bytesArgs: string[]): OperatorRegistrationArgs {
    if (bytesArgs.length < 4) handleError(ErrorType.INVALID_INPUT);
    const [_unusedHash, chainTypes, operatorAddresses, operatorAddress] = bytesArgs;

    return {
        chainTypes: JSON.parse(chainTypes),
        operatorAddresses: JSON.parse(operatorAddresses),
        operatorAddress,
    };
}
