import { decodeAbiParameters } from "viem";
import { hexToBytes } from "viem";

import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { DecodedArgs } from "../types";
import { decodeInternalMessageConfig, validateInternalMessageConfig } from "./messageConfig";

type EvmSrcChainData = {
	sender: string;
	blockNumber: string;
};

function decodeSrcChainData(srcChainSelector: bigint, srcChainData: string): EvmSrcChainData {
	const srcChainDataBytes = hexToBytes(srcChainData);

	return decodeAbiParameters(
		[
			{
				type: "tuple",
				components: [
					{ name: "sender", type: "address" },
					{ name: "blockNumber", type: "uint256" },
				],
			},
		],
		srcChainDataBytes,
	)[0];
}

export function decodeInputs(bytesArgs: string[]): DecodedArgs {
	if (bytesArgs.length < 6) {
		handleError(ErrorType.INVALID_BYTES_ARGS_LENGTH);
	}

	const [, internalMessageConfig, messageId, messageHashSum, srcChainData, operatorAddress] = bytesArgs;

	const decodedInternalMessageConfig = decodeInternalMessageConfig(internalMessageConfig);
	validateInternalMessageConfig(decodedInternalMessageConfig);

	const decodedArgs = {
		internalMessageConfig: decodedInternalMessageConfig,
		messageId,
		messageHashSum,
		srcChainData: decodeSrcChainData(decodedInternalMessageConfig.srcChainSelector, srcChainData),
		operatorAddress,
	};

	validateDecodedArgs(decodedArgs);
	return decodedArgs;
}

function validateDecodedArgs(args: DecodedArgs): void {
	// validateOperatorAddress(args.operatorAddress);
	validateMessageFields(args);
}

function isAddress(address: string): boolean {
	return address.length === 42 && address.startsWith("0x");
}

function validateOperatorAddress(address: string): void {
	if (!isAddress(address)) {
		handleError(ErrorType.INVALID_OPERATOR_ADDRESS);
	}
}

function validateMessageFields(args: DecodedArgs): void {
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
