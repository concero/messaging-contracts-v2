/**
 * Packs the result data into a binary format
 * @param messageReportResult - The message report result object
 * @returns Packed binary data as Uint8Array
 */
export function packResult(messageReportResult: {
    version: number;
    reportType: number;
    operator: string;
    internalMessageConfig: string;
    messageId: string;
    messageHashSum: string;
    dstChainData: string;
    allowedOperators: string[];
}): Uint8Array {
    const dstChainDataBytes = new Uint8Array(Buffer.from(messageReportResult.dstChainData.replace(/^0x/, ""), "hex"));
    const dstChainDataLength = dstChainDataBytes.length;

    const operatorsLength = messageReportResult.allowedOperators.length;
    const operatorsBytesLength = operatorsLength * 32; // Each operator is 32 bytes

    // Total length:
    // 1 byte (version) +
    // 1 byte (reportType) +
    // 32 bytes (operator address) +
    // 32 bytes (internal message config) +
    // 32 bytes (messageId) +
    // 32 bytes (messageHashSum) +
    // 4 bytes (dstChainData length) +
    // dynamic length (dstChainData) +
    // 2 bytes (operators count) +
    // (32 bytes * number of operators)
    const resLength = 1 + 1 + 32 + 32 + 32 + 32 + 4 + dstChainDataLength + 2 + operatorsBytesLength;

    const res = new Uint8Array(resLength);
    let offset = 0;

    res[offset] = messageReportResult.version;
    res[offset + 1] = messageReportResult.reportType;
    offset += 2;

    res.set(Functions.encodeUint256(BigInt(messageReportResult.operator)), offset);
    offset += 32;

    res.set(Functions.encodeUint256(BigInt(messageReportResult.internalMessageConfig)), offset);
    offset += 32;

    res.set(Functions.encodeUint256(BigInt(messageReportResult.messageId)), offset);
    offset += 32;

    res.set(Functions.encodeUint256(BigInt(messageReportResult.messageHashSum)), offset);
    offset += 32;

    res.set(new Uint8Array(new Uint32Array([dstChainDataLength]).buffer), offset);
    offset += 4;

    res.set(dstChainDataBytes, offset);
    offset += dstChainDataLength;

    res[offset] = operatorsLength >> 8;
    res[offset + 1] = operatorsLength & 0xff;
    offset += 2;

    for (let i = 0; i < operatorsLength; i++) {
        res.set(Functions.encodeUint256(BigInt(messageReportResult.allowedOperators[i])), offset);
        offset += 32;
    }

    return res;
}
