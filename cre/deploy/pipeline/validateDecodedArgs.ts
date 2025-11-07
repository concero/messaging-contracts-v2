import {DecodedArgs, DomainError, ErrorCode} from "../helpers";


export function validateDecodedArgs(decodedArgs: DecodedArgs): void {
    const { messageId, blockNumber, srcChainSelector } = decodedArgs;

    if (!messageId || messageId.length === 0) {
        throw new DomainError(ErrorCode.INVALID_MESSAGE_ID);
    }

    if (!blockNumber) {
        throw new DomainError(ErrorCode.INVALID_DATA);
    }

    if (!srcChainSelector) {
        throw new DomainError(ErrorCode.INVALID_CHAIN_DATA);
    }
}