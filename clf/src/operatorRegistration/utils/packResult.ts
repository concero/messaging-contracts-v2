import { OperatorRegistrationResult } from "../types";
import { COMMON_REPORT_BYTE_SIZES as COMMON_SIZES } from "../../common/reportBytes";
import { encodeUint256, packResponseConfig, hexToBytes, packUint32 } from "../../common/encoders";

/**
 * Packs the operator registration result into a binary format
 * @param result - The operator registration result object
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: OperatorRegistrationResult): Uint8Array {
    const chainTypesBytes = new TextEncoder().encode(JSON.stringify(result.chainTypes));
    const operatorAddressesBytes = new TextEncoder().encode(JSON.stringify(result.operatorAddresses));

    const bufferSize =
        COMMON_SIZES.WORD + // reportResponseConfig
        COMMON_SIZES.ARRAY_LENGTH + // chainTypesLength (uint32)
        chainTypesBytes.length +
        COMMON_SIZES.ARRAY_LENGTH + // operatorAddressesLength (uint32)
        operatorAddressesBytes.length;

    const res = new Uint8Array(bufferSize);
    let offset = 0;

    res.set(encodeUint256(packResponseConfig(result.reportType, result.version, result.requester)), offset);
    offset += COMMON_SIZES.WORD;

    // Pack chain types data
    res.set(packUint32(chainTypesBytes.length), offset);
    offset += COMMON_SIZES.ARRAY_LENGTH;

    res.set(chainTypesBytes, offset);
    offset += chainTypesBytes.length;

    // Pack operator addresses data
    res.set(packUint32(operatorAddressesBytes.length), offset);
    offset += COMMON_SIZES.ARRAY_LENGTH;

    res.set(operatorAddressesBytes, offset);

    return res;
}
