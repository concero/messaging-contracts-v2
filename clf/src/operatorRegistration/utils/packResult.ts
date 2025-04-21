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
	const encodedOperatorAddressesArr = result.operatorAddresses.map(operatorAddress =>
		encodeAbiParameters([{ type: "address" }], [operatorAddress]),
	);

	const payloadEncoded = encodeAbiParameters(
		[
			{
				type: "tuple",
				components: [
					{ type: "uint8[]", name: "operatorChains" },
					{ type: "uint8[]", name: "operatorActions" },
					{ type: "bytes[]", name: "operatorAddresses" },
				],
			},
		],
		[
			{
				operatorChains: result.chainTypes,
				operatorActions: result.actions,
				operatorAddresses: encodedOperatorAddressesArr,
			},
		],
	);

	const encodedResult = encodeAbiParameters(
		[
			{
				type: "tuple",
				name: "resultConfig",
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
