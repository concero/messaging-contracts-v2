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
//
// export function packResult(result: OperatorRegistrationResult): Uint8Array {
//     const chainTypesBytes = result.chainTypes.map(type => packUint8(type));
//     const actionsBytes = result.actions.map(action => packUint8(action));
//     const operatorAddressesBytes = result.operatorAddresses.map(addr => hexStringToUint8Array(addr.padStart(40, "0")));
//
//     const bufferSize =
//         COMMON_SIZES.WORD + // reportResponseConfig
//         COMMON_SIZES.ARRAY_LENGTH + // chainTypesLength
//         chainTypesBytes.length +
//         COMMON_SIZES.ARRAY_LENGTH + // actionsLength
//         actionsBytes.length +
//         COMMON_SIZES.ARRAY_LENGTH + // operatorAddressesLength
//         operatorAddressesBytes.length * COMMON_SIZES.ADDRESS; // Each address is 20 bytes
//
//     const res = new Uint8Array(bufferSize);
//     let offset = 0;
//
//     // Pack report config
//     res.set(encodeUint256(packResponseConfig(result.reportType, result.version, result.requester)), offset);
//     offset += COMMON_SIZES.WORD;
//
//     // Pack chain types
//     res.set(packUint32(chainTypesBytes.length), offset);
//     offset += COMMON_SIZES.ARRAY_LENGTH;
//     chainTypesBytes.forEach(bytes => {
//         res.set(bytes, offset);
//         offset += 1;
//     });
//
//     // Pack actions
//     res.set(packUint32(actionsBytes.length), offset);
//     offset += COMMON_SIZES.ARRAY_LENGTH;
//     actionsBytes.forEach(action => {
//         res.set(action, offset);
//         offset += 1;
//     });
//
//     // Pack operator addresses
//     res.set(packUint32(operatorAddressesBytes.length), offset);
//     offset += COMMON_SIZES.ARRAY_LENGTH;
//     operatorAddressesBytes.forEach(addr => {
//         res.set(addr, offset);
//         offset += COMMON_SIZES.ADDRESS;
//     });
//
//     return res;
// }
