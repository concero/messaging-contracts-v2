import { MessageReportResult } from "../types";
import { MESSAGE_REPORT_RESULT_SIZES as SIZES } from "../constants/bitOffsets";
import { MASKS } from "../../common/bitMasks";
import { encodeUint256 } from "../../common/encoders";

/**
 * Packs the message report result into a binary format
 * @param result - The message report result object to pack
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: MessageReportResult): Uint8Array {
    const dstChainDataBytes = new Uint8Array(Buffer.from(result.dstChainData.replace(/^0x/, ""), "hex"));
    const dstChainDataLength = dstChainDataBytes.length;
    const operatorsLength = result.allowedOperators.length;

    const operatorBytes = new Uint8Array(Buffer.from(result.operator.replace(/^0x/, ""), "hex"));
    const operatorLength = operatorBytes.length;

    let offset = 0;
    const res = new Uint8Array(
        SIZES.DST_CHAIN_DATA_LENGTH +
            dstChainDataLength +
            SIZES.OPERATOR_LENGTH +
            operatorLength +
            SIZES.OPERATORS_COUNT +
            operatorsLength * SIZES.OPERATOR_BYTES,
    );

    res[offset++] = result.version;
    res[offset++] = result.reportType;

    res.set(new Uint8Array([operatorLength]), offset);
    offset += SIZES.OPERATOR_LENGTH;
    res.set(operatorBytes, offset);
    offset += operatorLength;

    res.set(encodeUint256(BigInt(result.internalMessageConfig)), offset);
    offset += 32;
    res.set(encodeUint256(BigInt(result.messageId)), offset);
    offset += 32;
    res.set(encodeUint256(BigInt(result.messageHashSum)), offset);
    offset += 32;

    res.set(new Uint8Array(new Uint32Array([dstChainDataLength]).buffer), offset);
    offset += SIZES.DST_CHAIN_DATA_LENGTH;
    res.set(dstChainDataBytes, offset);
    offset += dstChainDataLength;

    res[offset++] = (operatorsLength & MASKS.UPPER_BYTE) >> MASKS.UPPER_BYTE_SHIFT;
    res[offset++] = operatorsLength & MASKS.LOWER_BYTE;

    for (const operator of result.allowedOperators) {
        const operatorBytes = new Uint8Array(Buffer.from(operator.replace(/^0x/, ""), "hex"));
        res.set(operatorBytes, offset);
        offset += operatorBytes.length;
    }

    return res;
}
