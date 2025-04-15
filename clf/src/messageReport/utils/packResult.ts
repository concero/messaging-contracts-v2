import { encodeAbiParameters } from "viem";
import type { Hash } from "viem";

import { hexStringToUint8Array } from "../../common/encoders";
import { MessageReportResult } from "../types";

/**
 * Packs the message report result into a binary format
 * @param result - The message report result object to pack
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: MessageReportResult, packedReportConfig: Hash): Uint8Array {
	// Using viem's encodeAbiParameters to encode data in the same format
	// as the Solidity abi.decode expects

	const encodedMessageDataV1 = encodeAbiParameters(
		[
			{ type: "uint8" }, // messageVersion
			{ type: "bytes32" }, // messageHashSum
			{ type: "bytes" }, // sender
			{ type: "uint24" }, // srcChainSelector
			{ type: "uint24" }, // dstChainSelector
			{ type: "bytes" }, // dstChainData
		],
		[
			result.messageVersion,
			result.messageHashSum,
			result.sender,
			result.srcChainSelector,
			result.dstChainSelector,
			result.dstChainData,
		],
	);

	const encodedClfMessageReportDataV1 = encodeAbiParameters(
		[
			{ type: "bytes32" }, // messageId
			{ type: "bytes[]" }, // allowedOperators
			{ type: "bytes" }, // encodedMessage
		],
		[result.messageId, result.allowedOperators, encodedMessageDataV1],
	);

	const encodedClfReport = encodeAbiParameters(
		[
			{ type: "bytes32" }, // reportConfig
			{ type: "bytes" }, // encodedMessage
		],
		[packedReportConfig, encodedClfMessageReportDataV1],
	);

	return hexStringToUint8Array(encodedClfReport);
}
