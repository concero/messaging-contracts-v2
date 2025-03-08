import { decodeAbiParameters, isAddress } from "viem";

import { ChainType } from "../../common/enums";
import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { OperatorRegistrationAction, OperatorRegistrationArgs } from "../types";

/**
 * Decodes and validates operator registration arguments from ethereum contract call
 * @param bytesArgs Array of encoded arguments from ethereum contract
 * @returns Parsed and validated OperatorRegistrationArgs
 */
export function validateInputs(bytesArgs: string[]): OperatorRegistrationArgs {
	if (bytesArgs.length < 5) {
		handleError(ErrorType.INVALID_BYTES_ARGS_LENGTH);
	}

	const decodedArgs = decodeInputs(bytesArgs);
	validateDecodedArgs(decodedArgs);

	return decodedArgs;
}

export function decodeInputs(bytesArgs: string[]): OperatorRegistrationArgs {
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
		handleError(ErrorType.DECODE_FAILED);
	}
}

export function validateDecodedArgs(args: OperatorRegistrationArgs): void {
	validateChainTypes(args.chainTypes);
	validateActions(args.actions);
	validateAddresses(args.operatorAddresses);
	validateOperatorAddress(args.requester);
	validateArrayLengths(args);
}

function validateChainTypes(chainTypes: number[]): void {
	const validChainTypes = new Set([ChainType.EVM, ChainType.NON_EVM]);

	if (!chainTypes.every(type => validChainTypes.has(type))) {
		handleError(ErrorType.INVALID_CHAIN_TYPE);
	}
}

/**
 * Validates registration actions are valid enum values
 */
function validateActions(actions: number[]): void {
	const validActions = new Set([OperatorRegistrationAction.REGISTER, OperatorRegistrationAction.DEREGISTER]);

	if (!actions.every(action => validActions.has(action))) {
		handleError(ErrorType.INVALID_ACTION);
	}
}

function validateAddresses(addresses: string[]): void {
	if (!addresses.every(address => isAddress(address, { strict: false }))) {
		handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
	}
}

function validateOperatorAddress(address: string): void {
	if (!isAddress(address, { strict: false })) {
		handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
	}
}

function validateArrayLengths(args: OperatorRegistrationArgs): void {
	const { chainTypes, actions, operatorAddresses } = args;

	if (chainTypes.length !== actions.length || actions.length !== operatorAddresses.length) {
		handleError(ErrorType.ARRAY_LENGTH_MISMATCH);
	}
}
