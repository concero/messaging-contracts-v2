import { decodeAbiParameters, isAddress } from "viem";

import { Relayer } from "./relayer";
import { CustomError, ErrorTypes } from "./error";
import { ChainType } from "./types";

export namespace Utility {
    export function validateInputs(bytesArgs: string[]): void {
        if (bytesArgs.length < 5) {
            throw new CustomError(ErrorTypes.Type.INVALID_BYTES_ARGS_LENGTH);
        }
    }

    export function decodeInputs(bytesArgs: string[]): Relayer.Registration.Args {
        const [_unusedHash, rawChainTypes, rawActions, rawOperatorAddresses, requester] = bytesArgs;

        try {
            const chainTypes = decodeAbiParameters([{ type: "uint8[]" }], rawChainTypes)[0];
            const actions = decodeAbiParameters([{ type: "uint8[]" }], rawActions)[0];
            const operatorAddresses = decodeAbiParameters([{ type: "address[]" }], rawOperatorAddresses)[0];

            return {
                chainTypes,
                actions,
                operatorAddresses,
                requester,
            };
        } catch (error) {
            throw new CustomError(ErrorTypes.Type.DECODE_FAILED);
        }
    }

    export function validateDecodedArgs(args: Relayer.Registration.Args): void {
        validateChainTypes(args.chainTypes);
        validateActions(args.actions);
        // validateAddresses(args.operatorAddresses);
        // validateOperatorAddress(args.requester);
        validateArrayLengths(args);
    }

    function validateChainTypes(chainTypes: number[]): void {
        const validChainTypes = new Set([ChainType.EVM, ChainType.NON_EVM]);

        if (!chainTypes.every(type => validChainTypes.has(type))) {
            throw new CustomError(ErrorTypes.Type.INVALID_CHAIN_TYPE);
        }
    }

    function validateActions(actions: number[]): void {
        const validActions = new Set([Relayer.Registration.Action.DEREGISTER, Relayer.Registration.Action.REGISTER]);

        if (!actions.every(action => validActions.has(action))) {
            throw new CustomError(ErrorTypes.Type.INVALID_ACTION);
        }
    }

    function validateAddresses(addresses: string[]): void {
        if (!addresses.every(address => isAddress(address, { strict: false }))) {
            throw new CustomError(ErrorTypes.Type.INVALID_OPERATOR_ADDRESS);
        }
    }

    function validateOperatorAddress(address: string): void {
        if (!isAddress(address, { strict: false })) {
            throw new CustomError(ErrorTypes.Type.INVALID_OPERATOR_ADDRESS);
        }
    }

    function validateArrayLengths(args: Relayer.Registration.Args): void {
        const { chainTypes, actions, operatorAddresses } = args;

        if (chainTypes.length !== actions.length || actions.length !== operatorAddresses.length) {
            throw new CustomError(ErrorTypes.Type.ARRAY_LENGTH_MISMATCH);
        }
    }
}