import { OPERATOR_REGISTRATION_RESULT_SIZES as SIZES } from "../constants/bitOffsets";
import { OperatorRegistrationResult } from "../types";

/**
 * Packs the operator registration result into a binary format
 * @param result - The operator registration result object
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: OperatorRegistrationResult): Uint8Array {
    const chainTypesBytes = new Uint8Array(Buffer.from(JSON.stringify(result.chainTypes)));
    const operatorAddressesBytes = new Uint8Array(Buffer.from(JSON.stringify(result.operatorAddresses)));

    let offset = 0;
    const res = new Uint8Array(
        SIZES.VERSION +
            SIZES.REPORT_TYPE +
            SIZES.OPERATOR +
            SIZES.CHAIN_TYPES_LENGTH +
            chainTypesBytes.length +
            SIZES.OPERATORS_COUNT +
            operatorAddressesBytes.length,
    );

    res[offset] = result.version;
    offset += SIZES.VERSION;

    res[offset] = result.reportType;
    offset += SIZES.REPORT_TYPE;

    res.set(new Uint8Array(Buffer.from(result.operator.replace(/^0x/, ""), "hex")), offset);
    offset += SIZES.OPERATOR;

    res.set(new Uint8Array(new Uint32Array([chainTypesBytes.length]).buffer), offset);
    offset += SIZES.CHAIN_TYPES_LENGTH;
    res.set(chainTypesBytes, offset);
    offset += chainTypesBytes.length;

    res.set(new Uint8Array(new Uint32Array([operatorAddressesBytes.length]).buffer), offset);
    offset += SIZES.OPERATORS_COUNT;
    res.set(operatorAddressesBytes, offset);

    return res;
}
