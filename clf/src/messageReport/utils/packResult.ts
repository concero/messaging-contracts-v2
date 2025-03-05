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
	const encoded = encodeAbiParameters(
		[
			{ type: "bytes32" }, // reportConfig
			{ type: "bytes32" }, // internalMessageConfig
			{ type: "bytes32" }, // messageId
			{ type: "bytes32" }, // messageHashSum
			{ type: "bytes" }, // dstChainData
			{ type: "bytes[]" }, // allowedOperators
		],
		[
			packedReportConfig,
			result.internalMessageConfig,
			result.messageId,
			result.messageHashSum,
			result.dstChainData,
			result.allowedOperators,
		],
	);

	return hexStringToUint8Array(encoded);
}

//   export function packResult(result: MessageReportResult): Uint8Array {
//     const dstChainDataBytes = hexStringToUint8Array(result.dstChainData);
//     const allowedOperatorsBytes = result.allowedOperators.map(hexStringToUint8Array);
//
//     const bufferSize =
//         COMMON_SIZES.WORD + // reportResponseConfig
//         COMMON_SIZES.WORD + // internalMessageConfig
//         COMMON_SIZES.WORD + // messageId
//         COMMON_SIZES.WORD + // messageHashSum
//         COMMON_SIZES.ARRAY_LENGTH + // dstChainDataLength (uint32)
//         dstChainDataBytes.length +
//         SIZES.ALLOWED_OPERATORS_LENGTH + // allowedOperatorsLength (uint16)
//         allowedOperatorsBytes.length * SIZES.ALLOWED_OPERATORS;
//
//     const res = new Uint8Array(bufferSize);
//     let offset = 0;
//
//     const fixedFields = [
//         packResponseConfig(result.reportType, result.version, result.requester),
//         BigInt(result.internalMessageConfig),
//         BigInt(result.messageId),
//         BigInt(result.messageHashSum),
//     ];
//
//     for (const field of fixedFields) {
//         res.set(hexStringToUint8Array(field.toString()), offset);
//         offset += COMMON_SIZES.WORD;
//     }
//
//     res.set(packUint32(dstChainDataBytes.length), offset);
//     offset += COMMON_SIZES.ARRAY_LENGTH;
//
//     res.set(dstChainDataBytes, offset);
//     offset += dstChainDataBytes.length;
//
//     res.set(hexStringToUint8Array(allowedOperatorsBytes.length.toString().padStart(64, "0")), offset);
//     offset += SIZES.ALLOWED_OPERATORS_LENGTH;
//
//     for (const operator of allowedOperatorsBytes) {
//         // if (operator.length !== SIZES.ALLOWED_OPERATORS) {
//         //     throw new Error(`Invalid operator address length: ${operator.length}`);
//         // }
//         res.set(operator, offset);
//         offset += SIZES.ALLOWED_OPERATORS;
//     }
//
//     return res;
// }
