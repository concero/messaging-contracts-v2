import { isAddress } from "viem";

import { CustomError, ErrorTypes } from "./error";
import { ChainType } from "./types";

export namespace Utility {
    export function validateInputs(bytesArgs: string[]): void {
        if (bytesArgs.length < 5) {
            throw new CustomError(ErrorTypes.Type.INVALID_BYTES_ARGS_LENGTH);
        }
    }

    export function validateChainTypes(chainTypes: number[]): void {
        const validChainTypes = new Set([ChainType.EVM, ChainType.NON_EVM]);

        if (!chainTypes.every(type => validChainTypes.has(type))) {
            throw new CustomError(ErrorTypes.Type.INVALID_CHAIN_TYPE);
        }
    }


    export function validateAddresses(addresses: string[]): void {
        if (!addresses.every(address => isAddress(address, { strict: false }))) {
            throw new CustomError(ErrorTypes.Type.INVALID_OPERATOR_ADDRESS);
        }
    }

    export function validateAddress(address: string): void {
        if (!isAddress(address, { strict: false })) {
            throw new CustomError(ErrorTypes.Type.INVALID_OPERATOR_ADDRESS);
        }
    }

}