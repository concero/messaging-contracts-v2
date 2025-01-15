import {
    OPERATOR_REGISTRATION_RESULT_SIZES as SIZES,
    OPERATOR_REGISTRATION_RESULT_OFFSETS as OFFSETS,
} from "../constants/bitOffsets";

/**
 * Packs the result data into a binary format
 * @param registrationReportResult - The registration report result object
 * @returns Packed binary data as Uint8Array
 */
export function packResult(registrationReportResult: {
    version: number;
    reportType: number;
    operator: string;
    chainTypes: number[];
    operatorAddresses: string[];
}): Uint8Array {
    const chainTypesBytes = new Uint8Array(Buffer.from(JSON.stringify(registrationReportResult.chainTypes)));
    const operatorAddressesBytes = new Uint8Array(
        Buffer.from(JSON.stringify(registrationReportResult.operatorAddresses)),
    );

    const resLength = OFFSETS.CHAIN_TYPES + chainTypesBytes.length + operatorAddressesBytes.length;

    const res = new Uint8Array(resLength);
    let offset = 0;

    res[OFFSETS.VERSION] = registrationReportResult.version;
    res[OFFSETS.REPORT_TYPE] = registrationReportResult.reportType;
    offset += 2;

    res.set(new Uint8Array(Buffer.from(registrationReportResult.operator.replace(/^0x/, ""), "hex")), OFFSETS.OPERATOR);
    offset += SIZES.OPERATOR;

    res.set(new Uint8Array(new Uint32Array([chainTypesBytes.length]).buffer), OFFSETS.CHAIN_TYPES_LENGTH);
    offset = OFFSETS.CHAIN_TYPES;

    res.set(chainTypesBytes, offset);
    offset += chainTypesBytes.length;

    res.set(new Uint8Array(new Uint32Array([operatorAddressesBytes.length]).buffer), offset);
    offset += SIZES.CHAIN_TYPES_LENGTH;

    res.set(operatorAddressesBytes, offset);

    return res;
}
