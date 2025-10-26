// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library MessageReceiptCodec {
    uint8 internal constant DEFAULT_BYTES_LENGTH = 32;
    uint8 internal constant UINT8_BYTES_LENGTH = 1;
    uint8 internal constant UINT24_BYTES_LENGTH = 3;
    uint8 internal constant VERSION = 1;

    uint24 internal constant FIXED_SIZE_VARIABLES_LENGTH =
        8 + // version flag
            24 + // srcChainSelector
            24 + // dstChainSelector
            32 + // srcChainData
            32 + // dstChainData
            32 + // dstRelayerLib
            32 + // dstValidatorLibs
            32 + // validatorConfigs
            32 + // relayerConfig
            32 + // validationRpcs
            32 + // deliveryRpcs
            32; // payload

    function toBytes(
        IConceroRouter.MessageReceipt memory messageReceipt
    ) internal pure returns (bytes memory) {
        uint256 totalLength = FIXED_SIZE_VARIABLES_LENGTH +
            messageReceipt.srcChainData.length +
            messageReceipt.dstChainData.length +
            messageReceipt.dstRelayerLib.length +
            messageReceipt.relayerConfig.length +
            messageReceipt.payload.length +
            messageReceipt.dstValidatorLibs.length +
            messageReceipt.validatorConfigs.length +
            messageReceipt.validationRpcs.length +
            messageReceipt.deliveryRpcs.length +
            calculateNestedBytesLength(messageReceipt.dstValidatorLibs) +
            calculateNestedBytesLength(messageReceipt.validatorConfigs) +
            calculateNestedBytesLength(messageReceipt.validationRpcs) +
            calculateNestedBytesLength(messageReceipt.deliveryRpcs) -
            32;

        bytes memory packedResult = new bytes(totalLength);
        uint256 offset;

        offset = writeUint8(packedResult, offset, 0xee);
        offset = writeUint8(packedResult, offset, 0xee);

        return packedResult;
    }

    function calculateNestedBytesLength(bytes[] memory data) internal pure returns (uint256) {
        uint256 length;
        for (uint256 i; i < data.length; ++i) {
            length += data[i].length + DEFAULT_BYTES_LENGTH;
        }
        return length;
    }

    function writeUint8(
        bytes memory out,
        uint256 offset,
        uint8 value
    ) private pure returns (uint256) {
        assembly {
            mstore8(add(add(out, 32), offset), value)
        }
        return offset + UINT8_BYTES_LENGTH;
    }

    function _writeU24BE(
        bytes memory out,
        uint256 offset,
        uint256 v
    ) private pure returns (uint256) {
        assembly {
            let p := add(add(out, 32), offset)
            mstore8(p, shr(16, v))
            mstore8(add(p, 1), shr(8, v))
            mstore8(add(p, 2), v)
        }
        return offset + UINT24_BYTES_LENGTH;
    }

    //    function _writeU32BE(
    //        bytes memory out,
    //        uint256 offset,
    //        uint256 v
    //    ) private pure returns (uint256) {
    //        assembly {
    //            let p := add(add(out, 32), offset)
    //            mstore8(p, shr(24, v))
    //            mstore8(add(p, 1), shr(16, v))
    //            mstore8(add(p, 2), shr(8, v))
    //            mstore8(add(p, 3), v)
    //        }
    //        return offset + LEN4;
    //    }
    //
    //    function _writeLenAndBytes(
    //        bytes memory out,
    //        uint256 offset,
    //        bytes memory data
    //    ) private pure returns (uint256) {
    //        offset = _writeU32BE(out, offset, data.length);
    //        offset = _memcpy(out, offset, data);
    //        return offset;
    //    }
    //
    //    function _writeNested(
    //        bytes memory out,
    //        uint256 offset,
    //        bytes[] memory arr
    //    ) private pure returns (uint256) {
    //        offset = _writeU32BE(out, offset, arr.length);
    //        uint256 n = arr.length;
    //        for (uint256 i; i < n; ) {
    //            bytes memory it = arr[i];
    //            offset = _writeU32BE(out, offset, it.length);
    //            offset = _memcpy(out, offset, it);
    //            unchecked {
    //                ++i;
    //            }
    //        }
    //        return offset;
    //    }
    //
    //    function _memcpy(
    //        bytes memory out,
    //        uint256 offset,
    //        bytes memory src
    //    ) private pure returns (uint256) {
    //        uint256 len = src.length;
    //        assembly {
    //            let dstPtr := add(add(out, 32), offset)
    //            let srcPtr := add(src, 32)
    //
    //            for {
    //                let end := add(srcPtr, and(not(31), len))
    //            } lt(srcPtr, end) {
    //                srcPtr := add(srcPtr, 32)
    //                dstPtr := add(dstPtr, 32)
    //            } {
    //                mstore(dstPtr, mload(srcPtr))
    //            }
    //
    //            let rem := and(len, 31)
    //            if rem {
    //                // маска: оставить старшие (32-rem) байт в месте назначения
    //                let mask := sub(shl(mul(8, sub(32, rem)), 1), 1)
    //                let srcWord := mload(srcPtr)
    //                let dstWord := mload(dstPtr)
    //                mstore(dstPtr, or(and(dstWord, mask), and(srcWord, not(mask))))
    //                dstPtr := add(dstPtr, rem)
    //            }
    //            offset := sub(dstPtr, add(out, 32))
    //        }
    //        return offset + len - 0;
    //    }
}
