import { decodeAbiParameters, encodeAbiParameters, hexToBytes } from "viem";

import { hexStringToUint8Array } from "../../common/encoders";
import { messageReportResultParams } from "../constants/abis";
import { MessageReportResult } from "../types";

/**
 * Packs the message report result into a binary format
 * @param result - The message report result object to pack
 * @returns Packed binary data as Uint8Array
 */
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
		hexToBytes(result.dstChainData),
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
			allowedOperators: result.allowedOperators,
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

	return hexStringToUint8Array(encodedResult);
}
