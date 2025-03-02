import { OperatorRegistrationResult } from "../types";
import { hexToBytes } from "../../common/encoders";
import { encodeAbiParameters } from "viem";
import type { Hash } from "viem";

/**
 * Packs the operator registration result into a binary format using viem's ABI encoder
 * 
 * @param result - The operator registration result object
 * @param reportConfig - Optional override for the report configuration
 * @returns Packed binary data as Uint8Array
 */
export function packResult(
  result: OperatorRegistrationResult,
  reportConfig: Hash,
): Uint8Array {
  const encoded = encodeAbiParameters(
    [
      { type: 'bytes32' },    // reportConfig
      { type: 'uint8[]' },    // chainTypes
      { type: 'uint8[]' },    // actions
      { type: 'address[]' }   // operatorAddresses
    ],
    [
      reportConfig,
      result.chainTypes,
      result.actions,
      result.operatorAddresses
    ]
  );
  
  return hexToBytes(encoded);
}