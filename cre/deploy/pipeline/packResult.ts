import { decodeAbiParameters, encodeAbiParameters, type Hex, hexToBytes, pad } from "viem";

import type { MessageReportResult } from "../types";
import { Utility } from "../utility";
import { messageReportResultParams } from "../constants";

export function packResult(result: MessageReportResult): Uint8Array {
    const decodedDstChainData = decodeAbiParameters(
        [
            {
                type: "tuple",
                components: [
                    { type: "address", name: "receiver" },
                    { type: "uint256", name: "gasLimit" },
                ],
            },
        ],
        hexToBytes(result.dstChainData as Hex),
    );

    const messagePayloadV1 = encodeAbiParameters(messageReportResultParams, [
        {
            messageId: result.messageId,
            messageHashSum: result.messageHashSum,
            messageSender: encodeAbiParameters([{ type: "address" }], [result.messageSender]),
            srcChainSelector: result.srcChainSelector,
            dstChainSelector: result.dstChainSelector,
            srcBlockNumber: result.srcBlockNumber,
            dstChainData: decodedDstChainData[0],
            allowedOperators: result.allowedOperators.map(op => pad(op as Hex)),
        },
    ]);

    const encodedResult = encodeAbiParameters(
        [
            {
                type: "tuple",
                components: [
                    { type: "uint8", name: "resultType" },
                    { type: "uint8", name: "payloadVersion" },
                    { type: "address", name: "requester" },
                ],
            }, // ResultConfig
            { type: "bytes" }, // payload
        ],
        [
            {
                resultType: result.resultType,
                payloadVersion: result.payloadVersion,
                requester: result.requester,
            },
            messagePayloadV1,
        ],
    );

    return Utility.hexStringToUint8Array(encodedResult);
}
