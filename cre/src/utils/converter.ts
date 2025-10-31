import { CustomError, ErrorTypes } from "../error";

export class Converter {
    static packUint32(value: number): Uint8Array {
        return new Uint8Array(new Uint32Array([value]).buffer);
    }

    static packUint16(value: number): Uint8Array {
        return new Uint8Array(new Uint16Array([value]).buffer);
    }

    static packUint8(value: number): Uint8Array {
        return new Uint8Array([value]);
    }

    static hexStringToUint8Array(hex: string): Uint8Array {
        hex = hex.replace(/^0x/, "");
        const length = hex.length / 2;
        const res = new Uint8Array(length);
        for (let i = 0; i < res.length; i++) {
            res[i] = parseInt(hex.slice(i * 2, i * 2 + 2), 16);
        }
        return res;
    }

    static encodeUint256(value: bigint) {
        if (value < 0n || value > (1n << 256n) - 1n) {
            throw new CustomError(ErrorTypes.Type.INVALID_UINT256);
        }
        return new Uint8Array(Buffer.from(value.toString(16).padStart(64, "0"), "hex"));
    }
}