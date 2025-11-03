import { ErrorCode, DomainError } from "./error";

export namespace Utility {
    /**
     * Converts a BigInt to a 32-byte (Uint256) buffer
     */
    export function encodeUint256(value: bigint) {
        if (value < 0n || value > (1n << 256n) - 1n) {
            throw new DomainError(ErrorCode.INVALID_UINT256);
        }
        return new Uint8Array(Buffer.from(value.toString(16).padStart(64, "0"), "hex"));
    }

    /**
     * Converts a hex string to Uint8Array
     * @param hex - Hex string with optional 0x prefix
     */
    export function hexStringToUint8Array(hex: string): Uint8Array {
        hex = hex.replace(/^0x/, "");
        const length = hex.length / 2;
        const res = new Uint8Array(length);
        for (let i = 0; i < res.length; i++) {
            res[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
        }
        return res;
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

    export function packUint8(value: number): Uint8Array {
        return new Uint8Array([value]);
    }

}
