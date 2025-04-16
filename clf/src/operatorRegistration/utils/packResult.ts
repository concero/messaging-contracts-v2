import { encodeAbiParameters } from "viem";
import type { Hash } from "viem";

import { hexStringToUint8Array } from "../../common/encoders";
import { OperatorRegistrationResult } from "../types";

/**
 * Packs the operator registration result into a binary format using viem's ABI encoder
 *
 * @param result - The operator registration result object
 * @param reportConfig - Optional override for the report configuration
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: OperatorRegistrationResult): Uint8Array {
	// First encode the OperatorRegistrationResult as payload
	const payloadEncoded = encodeAbiParameters(
		[
			{ type: "uint8[]" }, // operatorChains
			{ type: "uint8[]" }, // operatorActions
			{ type: "bytes[]" }, // operatorAddresses
		],
		[result.chainTypes, result.actions, result.operatorAddresses],
	);

	// Then encode the entire structure with ResultConfig and payload
	const finalEncoded = encodeAbiParameters(
		[
			{
				// ResultConfig struct
				type: "tuple",
				components: [
					{ type: "uint8", name: "resultType" },
					{ type: "uint8", name: "payloadVersion" },
					{ type: "address", name: "requester" },
				],
			},
			{ type: "bytes", name: "payload" }, // The encoded payload
		],
		[
			// ResultConfig values
			{
				resultType: result.resultType,
				payloadVersion: result.payloadVersion,
				requester: result.requester,
			},
			payloadEncoded, // The encoded payload
		],
	);

	return hexStringToUint8Array(finalEncoded);
}
