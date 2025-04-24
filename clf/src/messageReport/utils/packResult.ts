import { encodeAbiParameters } from "viem";
import type { Hash } from "viem";

import { hexStringToUint8Array } from "../../common/encoders";
import { MessageReportResult } from "../types";

/**
 * Packs the message report result into a binary format
 * @param result - The message report result object to pack
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: MessageReportResult): Uint8Array {
	const messagePayloadV1 = encodeAbiParameters(
		[
			{ type: "bytes32" }, // messageId
			{ type: "bytes32" }, // messageHashSum
			{ type: "bytes" }, // messageSender
			{ type: "uint24" }, // srcChainSelector
			{ type: "uint24" }, // dstChainSelector
			{
				type: "tuple",
				components: [
					{ type: "address", name: "receiver" },
					{ type: "bytes", name: "data" },
				],
			}, // dstChainData
			{ type: "bytes[]" }, // allowedOperators
		],
		[
			result.messageId
			result.messageHashSum,
			result.messageSender,
			result.srcChainSelector,
			result.dstChainSelector,
			result.dstChainData,
			result.allowedOperators,
		],
	);

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
