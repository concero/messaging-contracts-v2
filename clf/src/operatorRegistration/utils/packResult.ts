import { encodeAbiParameters } from "viem";

import { hexStringToUint8Array } from "../../common/encoders";
import { OperatorRegistrationResult } from "../types";

/**
 * Packs the operator registration result into a binary format using viem's ABI encoder
 *
 * @param result - The operator registration result object
 * @returns Packed binary data as Uint8Array
 */
export function packResult(result: OperatorRegistrationResult): Uint8Array {
	const payloadEncoded = encodeAbiParameters(
		[
			{ type: "uint8[]" }, // operatorChains
			{ type: "uint8[]" }, // operatorActions
			{ type: "bytes[]" }, // operatorAddresses
		],
		[result.chainTypes, result.actions, result.operatorAddresses],
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
			},
			{ type: "bytes", name: "payload" },
		],
		[
			{
				resultType: result.resultType,
				payloadVersion: result.payloadVersion,
				requester: result.requester,
			},
			payloadEncoded,
		],
	);

	return hexStringToUint8Array(encodedResult);
}
