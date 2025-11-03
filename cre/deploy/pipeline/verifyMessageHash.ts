import { type Hash, type Hex, keccak256 } from "viem";

import { DomainError, ErrorCode } from "../error";

export function verifyMessageHash(message: Hex, expectedHashSum: Hash): void {
    if (keccak256(message).toLowerCase() !== expectedHashSum.toLowerCase()) {
        throw new DomainError(ErrorCode.INVALID_HASHSUM);
    }
}