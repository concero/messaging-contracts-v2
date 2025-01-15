import { MessageArgs } from "../types";
import { ErrorType } from "../constants/errorTypes";
import { handleError } from "../../common/errorHandler";

export function validateInputs(bytesArgs: string[]): MessageArgs {
    if (bytesArgs.length < 6) handleError(ErrorType.INVALID_INPUT);
    const [_unusedHash, internalMessageConfig, messageId, messageHashSum, srcChainData, operatorAddress] = bytesArgs;

    return {
        internalMessageConfig,
        messageId,
        messageHashSum,
        srcChainData,
        operatorAddress,
    };
}
