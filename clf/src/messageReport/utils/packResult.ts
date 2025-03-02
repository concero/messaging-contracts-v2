import { MessageReportResult } from "../types";
import { REPORT_BYTE_SIZES as SIZES } from "../constants/reportBytes";
import { COMMON_REPORT_BYTE_SIZES as COMMON_SIZES } from "../../common/reportBytes";
import { encodeUint256, packResponseConfig, hexToBytes, packUint16, packUint32 } from "../../common/encoders";

/**
 * Packs the message report result into a binary format
 * @param result - The message report result object to pack
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: MessageReportResult): Uint8Array {
    const dstChainDataBytes = hexToBytes(result.dstChainData);
    const allowedOperatorsBytes = result.allowedOperators.map(hexToBytes);

    const bufferSize =
        COMMON_SIZES.WORD + // reportResponseConfig
        COMMON_SIZES.WORD + // internalMessageConfig
        COMMON_SIZES.WORD + // messageId
        COMMON_SIZES.WORD + // messageHashSum
        COMMON_SIZES.ARRAY_LENGTH + // dstChainDataLength (uint32)
        dstChainDataBytes.length +
        SIZES.ALLOWED_OPERATORS_LENGTH + // allowedOperatorsLength (uint16)
        allowedOperatorsBytes.length * SIZES.ALLOWED_OPERATORS;

    const res = new Uint8Array(bufferSize);
    let offset = 0;

    const fixedFields = [
        packResponseConfig(result.reportType, result.version, result.requester),
        BigInt(result.internalMessageConfig),
        BigInt(result.messageId),
        BigInt(result.messageHashSum),
    ];

    for (const field of fixedFields) {
        res.set(encodeUint256(field), offset);
        offset += COMMON_SIZES.WORD;
    }

    res.set(packUint32(dstChainDataBytes.length), offset);
    offset += COMMON_SIZES.ARRAY_LENGTH;

    res.set(dstChainDataBytes, offset);
    offset += dstChainDataBytes.length;

    res.set(packUint16(allowedOperatorsBytes.length), offset);
    offset += SIZES.ALLOWED_OPERATORS_LENGTH;

    for (const operator of allowedOperatorsBytes) {
        if (operator.length !== SIZES.ALLOWED_OPERATORS) {
            throw new Error(`Invalid operator address length: ${operator.length}`);
        }
        res.set(operator, offset);
        offset += SIZES.ALLOWED_OPERATORS;
    }

    return res;
}
