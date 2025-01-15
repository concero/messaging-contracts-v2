import { MessageReportResult } from "../types";
import {
    MASKS,
    MESSAGE_REPORT_RESULT_OFFSETS as OFFSETS,
    MESSAGE_REPORT_RESULT_SIZES as SIZES,
} from "../constants/bitOffsets";

/**
 * Calculates the total length of the result buffer
 */
function calculateResultLength(dstChainDataLength: number, operatorsLength: number): number {
    const fixedLength = OFFSETS.DST_CHAIN_LENGTH + SIZES.DST_CHAIN_DATA_LENGTH;
    return fixedLength + dstChainDataLength + SIZES.OPERATORS_COUNT + operatorsLength * SIZES.OPERATOR_BYTES;
}

/**
 * Packs the result data into a binary format
 */
export function packResult(result: MessageReportResult): Uint8Array {
    const dstChainDataBytes = new Uint8Array(Buffer.from(result.dstChainData.replace(/^0x/, ""), "hex"));
    const dstChainDataLength = dstChainDataBytes.length;
    const operatorsLength = result.allowedOperators.length;

    const res = new Uint8Array(calculateResultLength(dstChainDataLength, operatorsLength));

    // Pack fixed fields
    res[OFFSETS.VERSION] = result.version;
    res[OFFSETS.REPORT_TYPE] = result.reportType;

    res.set(Functions.encodeUint256(BigInt(result.operator)), OFFSETS.OPERATOR);
    res.set(Functions.encodeUint256(BigInt(result.internalMessageConfig)), OFFSETS.MESSAGE_CONFIG);
    res.set(Functions.encodeUint256(BigInt(result.messageId)), OFFSETS.MESSAGE_ID);
    res.set(Functions.encodeUint256(BigInt(result.messageHashSum)), OFFSETS.MESSAGE_HASH);

    // Pack destination chain data
    let offset = OFFSETS.DST_CHAIN_LENGTH;
    res.set(new Uint8Array(new Uint32Array([dstChainDataLength]).buffer), offset);
    offset += SIZES.DST_CHAIN_DATA_LENGTH;

    res.set(dstChainDataBytes, offset);
    offset += dstChainDataLength;

    // Pack operators count
    res[offset] = (operatorsLength & MASKS.UPPER_BYTE) >> MASKS.UPPER_BYTE_SHIFT;
    res[offset + 1] = operatorsLength & MASKS.LOWER_BYTE;
    offset += SIZES.OPERATORS_COUNT;

    // Pack operators
    for (const operator of result.allowedOperators) {
        res.set(Functions.encodeUint256(BigInt(operator)), offset);
        offset += SIZES.OPERATOR_BYTES;
    }

    return res;
}
