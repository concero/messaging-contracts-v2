import { handleError } from "./errorHandler";
import { ErrorType } from "./errorType";

/**
 * Converts a BigInt to a 32-byte (Uint256) buffer
 */
export function encodeUint256(value: bigint) {
    if (value < 0n || value > (1n << 256n) - 1n) {
        handleError(ErrorType.INVALID_UINT256);
    }
    return new Uint8Array(Buffer.from(value.toString(16).padStart(64, "0"), "hex"));
}
