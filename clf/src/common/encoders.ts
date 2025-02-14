import { handleError } from "./errorHandler";
import { ErrorType } from "./errorType";
import { REPORT_BYTE_OFFSETS } from "./reportByteConstants";

/**
 * Converts a BigInt to a 32-byte (Uint256) buffer
 */
export function encodeUint256(value: bigint) {
    if (value < 0n || value > (1n << 256n) - 1n) {
        handleError(ErrorType.INVALID_UINT256);
    }
    return new Uint8Array(Buffer.from(value.toString(16).padStart(64, "0"), "hex"));
}

/**
 * Converts a hex string to Uint8Array
 * @param hex - Hex string with optional 0x prefix
 */
export function hexToBytes(hex: string): Uint8Array {
    return new Uint8Array(Buffer.from(hex.replace(/^0x/, ""), "hex"));
}

/**
 * Packs a number into a 4-byte big-endian Uint8Array
 * @param value - Number to pack
 */
export function packUint32(value: number): Uint8Array {
    return new Uint8Array(new Uint32Array([value]).buffer);
}

/**
 * Packs a number into a 2-byte big-endian Uint8Array
 * @param value - Number to pack
 */
export function packUint16(value: number): Uint8Array {
    return new Uint8Array(new Uint16Array([value]).buffer);
}

/**
 * Packs CLF report response configuration into a single uint256
 * @param reportType - Report type (8 bits)
 * @param version - Version number (8 bits)
 * @param requester - Ethereum address (160 bits)
 * @returns Packed configuration as BigInt
 */
export function packResponseConfig(reportType: number, version: number, requester: string): bigint {
    return (
        (BigInt(reportType) << BigInt(REPORT_BYTE_OFFSETS.REPORT_TYPE)) |
        (BigInt(version) << BigInt(REPORT_BYTE_OFFSETS.VERSION)) |
        (BigInt(`0x${requester.replace(/^0x/, "")}`) & REPORT_BYTE_OFFSETS.REQUESTER_MASK)
    );
}
