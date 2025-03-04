import { MessageReportResult } from "../types";
import { hexToBytes } from "../../common/encoders";
import { encodeAbiParameters } from "viem";
import type { Hash } from "viem";

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
        { type: 'bytes32' },    // reportConfig
        { type: 'bytes32' },    // internalMessageConfig
        { type: 'bytes32' },    // messageId
        { type: 'bytes32' },    // messageHashSum
        { type: 'bytes' },      // dstChainData
        { type: 'bytes[]' }     // allowedOperators
      ],
      [
        packedReportConfig,
        result.internalMessageConfig,
        result.messageId,
        result.messageHashSum,
        result.dstChainData,
        result.allowedOperators
      ]
    );
    
    return hexToBytes(encoded);
  }
  