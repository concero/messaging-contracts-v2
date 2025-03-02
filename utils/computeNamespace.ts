import { encodeAbiParameters, encodePacked, keccak256 } from "viem";

/**
 * @notice Converts a BigInt into a 32-byte hex string.
 * @param {bigint} value The BigInt value to convert.
 * @return {string} The 0x-prefixed 32-byte hex string.
 */
function toHex32(value) {
	return `0x${value.toString(16).padStart(64, "0")}`;
}

/**
 * @notice Encodes a uint256 value as a 32-byte hex string.
 * @param {bigint} value The BigInt value to encode.
 * @return {string} The encoded 32-byte hex string.
 */
function encodeUint256(value) {
	return toHex32(value);
}

/**
 * @notice Computes a namespace constant analogous to the Solidity implementation.
 * @param {string} identifier The namespace identifier string.
 * @return {string} The computed 32-byte hex namespace.
 */
function computeNamespace(identifier: string): `0x${string}` {
	// 1. First keccak256 and conversion to uint256
	const innerHash = keccak256(encodePacked(["string"], [identifier]));
	const innerBigInt = BigInt(innerHash);

	// 2. Subtract 1
	const subtracted = innerBigInt - 1n;

	// 3. abi.encode equivalent - encode as uint256
	const encoded = encodeAbiParameters([{ type: "uint256" }], [subtracted]);

	// 4. Final keccak256
	const outerHash = keccak256(encoded);

	// 5. Mask off the last byte (equivalent to ~bytes32(uint256(0xff)))
	const mask = ~BigInt(0xff);
	const maskedValue = BigInt(outerHash) & mask;

	// 6. Convert back to hex string
	return `0x${maskedValue.toString(16).padStart(64, "0")}` as `0x${string}`;
}

export { computeNamespace };
