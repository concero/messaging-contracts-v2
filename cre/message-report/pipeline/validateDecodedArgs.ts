import {DecodedArgs, DomainError, ErrorCode} from "../helpers";


export function validateDecodedArgs(decodedArgs: DecodedArgs): void {

    if (!decodedArgs.batches.length) {
        throw new DomainError(ErrorCode.INVALID_DATA, 'Batches list is empty')
    }

    for (const batch of decodedArgs.batches) {
        if (!batch.messageId || batch.messageId.length === 0) {
            throw new DomainError(ErrorCode.INVALID_MESSAGE_ID);
        }

        if (!batch.blockNumber) {
            throw new DomainError(ErrorCode.INVALID_DATA);
        }

        if (!batch.srcChainSelector) {
            throw new DomainError(ErrorCode.INVALID_CHAIN_DATA);
        }
    }

}