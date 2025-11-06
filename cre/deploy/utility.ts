import { DomainError, ErrorCode } from "./error";

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

    export const safeJSONStringify = (obj: object) =>
        JSON.stringify(obj, (_, value) =>
            typeof value === 'bigint' ? `0x${value.toString(16)}` : value
        );

    export const safeJSONParse = <T = any>(json: string): T => {
        if (typeof json !== "string") {
            json = JSON.stringify(json);
        }

        const parsed = JSON.parse(json, (key, value) => {
            if (key === "blockNumber" && typeof value === "string" && /^0x[0-9a-fA-F]+$/.test(value)) {
                try {
                    return BigInt(value);
                } catch {
                    return value;
                }
            }
            return value;
        });

        if (
            parsed &&
            typeof parsed === "object" &&
            !Array.isArray(parsed) &&
            Object.keys(parsed).every(k => /^\d+$/.test(k))
        ) {
            return Object.values(parsed) as T;
        }

        return parsed;
    };



}
