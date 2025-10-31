import { decodeAbiParameters, hexToBytes } from "viem";

import { CustomError, ErrorTypes } from "../error";
import { DecodedArgs } from "./types";

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
                    { name: "blockNumber", type: "uint256" },
                    { name: "sender", type: "address" },
                ],
            },
        ],
        srcChainDataBytes,
    )[0];
}

export function decodeInputs(bytesArgs: string[]): DecodedArgs {
    if (bytesArgs.length < 6) {
        throw new CustomError(ErrorTypes.Type.INVALID_BYTES_ARGS_LENGTH);
    }

    const [, hexSrcChainSelector, messageId, messageHashSum, srcChainData, operatorAddress] = bytesArgs;
    const srcChainSelector = Number(hexSrcChainSelector);

    const decodedArgs = {
        srcChainSelector,
        messageId,
        messageHashSum,
        srcChainData: decodeSrcChainData(srcChainSelector, srcChainData),
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
        throw new CustomError(ErrorTypes.Type.INVALID_OPERATOR_ADDRESS);
    }
}

function validateMessageFields(args: DecodedArgs): void {
    const { messageId, messageHashSum, srcChainData } = args;

    if (!messageId || messageId.length === 0) {
        throw new CustomError(ErrorTypes.Type.INVALID_MESSAGE_ID);
    }

    if (!messageHashSum || messageHashSum.length === 0) {
        throw new CustomError(ErrorTypes.Type.INVALID_HASH_SUM);
    }

    if (!srcChainData || srcChainData.length === 0) {
        throw new CustomError(ErrorTypes.Type.INVALID_CHAIN_DATA);
    }
}
