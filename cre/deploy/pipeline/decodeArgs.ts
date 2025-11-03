import { type Address, decodeAbiParameters, type Hex } from "viem";
import { decodeJson, HTTPPayload } from "@chainlink/cre-sdk";

import { DomainError, ErrorCode } from "../error";
import { EvmSrcChainDataParams } from "../constants";
import { type DecodedArgs, type EvmSrcChainData } from "../types";

export function decodeEvmSrcChainData(encodedData: Hex): EvmSrcChainData {
    try {
        const [sender, blockNumber] = decodeAbiParameters(EvmSrcChainDataParams, encodedData) as [sender: Hex, blockNumber: bigint];

        return {
            sender,
            blockNumber: blockNumber.toString(),
        };
    } catch (error) {
        throw new DomainError(ErrorCode.INVALID_DATA);
    }
}

export function decodeArgs(payload: HTTPPayload): DecodedArgs {
    try {
        const bytesArgs = decodeJson(payload.input)?.args;

        if (!bytesArgs || bytesArgs.length < 6) {
            throw new DomainError(ErrorCode.INVALID_BYTES_ARGS_LENGTH);
        }

        const [_, hexSrcChainSelector, messageId, messageHashSum, srcChainData, operatorAddress] = bytesArgs as unknown as [
            _: unknown,
            hexSrcChainSelector: Hex,
            messageId: Hex,
            messageHashSum: Hex,
            srcChainData: Hex,
            operatorAddress: Address
        ];
        const srcChainSelector = Number(hexSrcChainSelector);

        return {
            srcChainSelector,
            messageId,
            messageHashSum,
            srcChainData: decodeEvmSrcChainData(srcChainData),
            operatorAddress,
        };
    } catch (e) {
        throw new DomainError(ErrorCode.INVALID_DATA);
    }
}
