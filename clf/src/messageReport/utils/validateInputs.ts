import { decodeAbiParameters, isAddress } from "viem";
import { MessageArgs } from "../types";
import { ErrorType } from "../../common/errorType";
import { handleError } from "../../common/errorHandler";
import { clf } from "../../../../tasks";

/**
 * Decodes and validates message report arguments from ethereum contract call
 * @param bytesArgs Array of encoded arguments from ethereum contract
 * @returns Parsed and validated MessageArgs
 * @throws If decoding fails or validation errors occur
 */
export function validateInputs(bytesArgs: string[]): MessageArgs {
    console.log("bytesArgs", bytesArgs);
    if (bytesArgs.length < 6) {
        handleError(ErrorType.INVALID_BYTES_ARGS_LENGTH);
    }

    const decodedArgs = decodeInputs(bytesArgs);
    validateDecodedArgs(decodedArgs);

    return decodedArgs;
}

function decodeInputs(bytesArgs: string[]): MessageArgs {
    const [_unusedHash, internalMessageConfig, messageId, messageHashSum, srcChainData, operatorAddress] = bytesArgs;

    try {
        return {
            internalMessageConfig: decodeAbiParameters([{ type: "bytes" }], internalMessageConfig)[0],
            messageId: decodeAbiParameters([{ type: "bytes32" }], messageId)[0],
            messageHashSum: decodeAbiParameters([{ type: "bytes32" }], messageHashSum)[0],
            srcChainData: decodeAbiParameters([{ type: "bytes" }], srcChainData)[0],
            operatorAddress,
        };
    } catch (error) {
        handleError(ErrorType.DECODE_FAILED);
    }
}

function validateDecodedArgs(args: MessageArgs): void {
    validateOperatorAddress(args.operatorAddress);
    validateMessageFields(args);
}

function validateOperatorAddress(address: string): void {
    if (!isAddress(address)) {
        handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
    }
}

function validateMessageFields(args: MessageArgs): void {
    const { internalMessageConfig, messageId, messageHashSum, srcChainData } = args;

    if (!internalMessageConfig || internalMessageConfig.length === 0) {
        handleError(ErrorType.INVALID_MESSAGE_CONFIG);
    }

    if (!messageId || messageId.length === 0) {
        handleError(ErrorType.INVALID_MESSAGE_ID);
    }

    if (!messageHashSum || messageHashSum.length === 0) {
        handleError(ErrorType.INVALID_HASH_SUM);
    }

    if (!srcChainData || srcChainData.length === 0) {
        handleError(ErrorType.INVALID_CHAIN_DATA);
    }
}
