import { OperatorRegistrationResult } from "../types";
import { COMMON_REPORT_BYTE_SIZES as COMMON_SIZES } from "../../common/reportBytes";
import { encodeUint256, packResponseConfig, hexToBytes, packUint32, packUint8 } from "../../common/encoders";

/**
 * Packs the operator registration result into a binary format
 * @param result - The operator registration result object
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: OperatorRegistrationResult): Uint8Array {
    const chainTypesBytes = result.chainTypes.map(type => packUint8(type));
    const actionsBytes = result.actions.map(action => packUint8(action));
    const operatorAddressesBytes = result.operatorAddresses.map(addr => hexToBytes(addr.padStart(40, "0")));

    const bufferSize =
        COMMON_SIZES.WORD + // reportResponseConfig
        COMMON_SIZES.ARRAY_LENGTH + // chainTypesLength
        chainTypesBytes.length +
        COMMON_SIZES.ARRAY_LENGTH + // actionsLength
        actionsBytes.length +
        COMMON_SIZES.ARRAY_LENGTH + // operatorAddressesLength
        operatorAddressesBytes.length * COMMON_SIZES.ADDRESS; // Each address is 20 bytes

    const res = new Uint8Array(bufferSize);
    let offset = 0;

    // Pack report config
    res.set(encodeUint256(packResponseConfig(result.reportType, result.version, result.requester)), offset);
    offset += COMMON_SIZES.WORD;

    // Pack chain types
    res.set(packUint32(chainTypesBytes.length), offset);
    offset += COMMON_SIZES.ARRAY_LENGTH;
    chainTypesBytes.forEach(bytes => {
        res.set(bytes, offset);
        offset += 1;
    });

    // Pack actions
    res.set(packUint32(actionsBytes.length), offset);
    offset += COMMON_SIZES.ARRAY_LENGTH;
    actionsBytes.forEach(action => {
        res.set(action, offset);
        offset += 1;
    });

    // Pack operator addresses
    res.set(packUint32(operatorAddressesBytes.length), offset);
    offset += COMMON_SIZES.ARRAY_LENGTH;
    operatorAddressesBytes.forEach(addr => {
        res.set(addr, offset);
        offset += COMMON_SIZES.ADDRESS;
    });

    return res;
}
