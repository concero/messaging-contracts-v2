import { isAddress } from "viem";

import { DomainError, ErrorCode } from "../error";
import type { DecodedArgs } from "../types";


export function validateDecodedArgs(decodedArgs: DecodedArgs): void {
    const { messageId, messageHashSum, srcChainData, operatorAddress } = decodedArgs;


    if (!isAddress(operatorAddress)) {
        throw new DomainError(ErrorCode.INVALID_OPERATOR_ADDRESS);
    }


    if (!messageId || messageId.length === 0) {
        throw new DomainError(ErrorCode.INVALID_MESSAGE_ID);
    }

    if (!messageHashSum || messageHashSum.length === 0) {
        throw new DomainError(ErrorCode.INVALID_HASH_SUM);
    }

    if (!srcChainData || !srcChainData.sender || !srcChainData.blockNumber) {
        throw new DomainError(ErrorCode.INVALID_CHAIN_DATA);
    }
}