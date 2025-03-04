import { type Address, hexToBigInt } from "viem";

import { COMMON_REPORT_BYTE_OFFSETS } from "./reportBytes";

/**
 * Packs the report configuration into a bytes32 value according to the defined bit layout
 *
 * @param reportType - 8-bit report type identifier
 * @param version - 8-bit version number
 * @param requester - Ethereum address of the requester (20-byte EVM address)
 * @returns A bytes32 (as hex string) with the packed configuration
 */
export function packReportConfig(
	reportType: number,
	version: number,
	requester: Address,
): `0x${string}` {
	if (reportType < 0 || reportType > 255) throw new Error("reportType must be a uint8 (0-255)");
	if (version < 0 || version > 255) throw new Error("version must be a uint8 (0-255)");

	// Convert to BigInt for bit operations using the offsets from reportBytes
	const reportTypeBits = BigInt(reportType) << BigInt(COMMON_REPORT_BYTE_OFFSETS.REPORT_TYPE);
	const versionBits = BigInt(version) << BigInt(COMMON_REPORT_BYTE_OFFSETS.VERSION);

	// For requester, we just need the lowest 160 bits (20 bytes) of the address
	// Since hexToBigInt already gives us the correct representation, we don't need to shift
	// The address will naturally occupy the lowest 160 bits (address is already in correct position)
	const requesterBits = hexToBigInt(requester) & COMMON_REPORT_BYTE_OFFSETS.REQUESTER_MASK;

	// Combine all parts with bitwise OR
	const packedValue = reportTypeBits | versionBits | requesterBits;

	// Convert to hex string representation
	return `0x${packedValue.toString(16).padStart(64, "0")}`;
}
