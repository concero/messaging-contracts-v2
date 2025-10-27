// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import "forge-std/src/console.sol";
import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library MessageReceiptCodec {
    uint8 internal constant DEFAULT_BYTES_LENGTH = 32;
    uint8 internal constant UINT8_BYTES_LENGTH = 1;
    uint8 internal constant UINT24_BYTES_LENGTH = 3;
    uint8 internal constant UINT32_BYTES_LENGTH = 4;
    uint8 internal constant UINT64_BYTES_LENGTH = 8;
    uint8 internal constant BYTES32_BYTES_LENGTH = 32;
    uint8 internal constant ADDRESS_BYTES_LENGTH = 20;
    uint8 internal constant VERSION = 1;

    uint24 internal constant FIXED_SIZE_VARIABLES_LENGTH =
        8 + // version flag
            24 + // srcChainSelector
            24 + // dstChainSelector
            32 + // srcChainData length
            32 + // dstChainData length
            32 + // dstRelayerLib length
            32 + // dstValidatorLibs length
            32 + // validatorConfigs length
            32 + // relayerConfig length
            32 + // validationRpcs length
            32 + // deliveryRpcs length
            32; // payload length

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
        uint256 offset = 32;

        offset = writeUint8(packedResult, offset, VERSION);
        offset = writeUint24(packedResult, offset, messageReceipt.srcChainSelector);
        offset = writeLenAndBytes(packedResult, offset, messageReceipt.srcChainData);

        return packedResult;
    }

    function toMessageReceiptBytes(
        IConceroRouter.MessageRequest memory messageRequest,
        uint24 srcChainSelector,
        address msgSender,
        bytes memory dstRelayerLib,
        bytes[] memory dstValidatorLibs
    ) internal pure returns (bytes memory) {
        uint256 totalLength = calculateTotalLength(messageRequest, dstRelayerLib, dstValidatorLibs);

        bytes memory packedResult = new bytes(totalLength);
        uint256 offset = 32;

        offset = writeUint8(packedResult, offset, VERSION);
        offset = writeUint24(packedResult, offset, srcChainSelector);
        offset = writeUint24(packedResult, offset, messageRequest.dstChainSelector);
        offset = writeUint64(packedResult, offset, messageRequest.srcBlockConfirmations);
        offset = writeAddress(packedResult, offset, msgSender);
        offset = writeLenAndBytes(packedResult, offset, messageRequest.dstChainData);
        offset = writeLenAndBytes(packedResult, offset, dstRelayerLib);
        offset = writeLenAndBytes(packedResult, offset, messageRequest.relayerConfig);
        offset = writeNestedBytes(packedResult, offset, dstValidatorLibs);
        offset = writeNestedBytes(packedResult, offset, messageRequest.validatorConfigs);
        offset = writeNestedBytes(packedResult, offset, messageRequest.validationRpcs);
        offset = writeNestedBytes(packedResult, offset, messageRequest.deliveryRpcs);
        writeLenAndBytes(packedResult, offset, messageRequest.payload);

        return packedResult;
    }

    function calculateTotalLength(
        IConceroRouter.MessageRequest memory messageRequest,
        bytes memory dstRelayerLib,
        bytes[] memory dstValidatorLibs
    ) private pure returns (uint256) {
        return
            FIXED_SIZE_VARIABLES_LENGTH +
            UINT24_BYTES_LENGTH +
            UINT64_BYTES_LENGTH + // srcChainData
            messageRequest.dstChainData.length +
            dstRelayerLib.length +
            messageRequest.relayerConfig.length +
            messageRequest.payload.length +
            dstValidatorLibs.length +
            messageRequest.validatorConfigs.length +
            messageRequest.validationRpcs.length +
            messageRequest.deliveryRpcs.length +
            calculateNestedBytesLength(dstValidatorLibs) +
            calculateNestedBytesLength(messageRequest.validatorConfigs) +
            calculateNestedBytesLength(messageRequest.validationRpcs) +
            calculateNestedBytesLength(messageRequest.deliveryRpcs) -
            32;
    }

    function writeUint8(
        bytes memory out,
        uint256 offset,
        uint8 value
    ) private pure returns (uint256) {
        assembly {
            mstore8(add(out, offset), value)
        }
        return offset + UINT8_BYTES_LENGTH;

        //        out[offset] = bytes1(value);
        //        unchecked {
        //            return offset + UINT8_BYTES_LENGTH;
        //        }
    }

    function writeUint24(
        bytes memory out,
        uint256 offset,
        uint24 value
    ) private pure returns (uint256) {
        assembly {
            let ptr := add(out, offset)
            mstore8(ptr, shr(16, value))
            mstore8(add(ptr, 1), shr(8, value))
            mstore8(add(ptr, 2), value)
        }
        return offset + UINT24_BYTES_LENGTH;

        //        out[offset] = bytes1(uint8(value >> 16));
        //        out[offset + 1] = bytes1(uint8(value >> 8));
        //        out[offset + 2] = bytes1(uint8(value));
        //        unchecked {
        //            return offset + UINT24_BYTES_LENGTH;
        //        }
    }

    function writeUint32(
        bytes memory out,
        uint256 offset,
        uint32 value
    ) private pure returns (uint256) {
        assembly {
            let ptr := add(out, offset)
            mstore8(ptr, shr(24, value))
            mstore8(add(ptr, 1), shr(16, value))
            mstore8(add(ptr, 2), shr(8, value))
            mstore8(add(ptr, 3), value)
        }

        return offset + UINT32_BYTES_LENGTH;

        //        out[offset] = bytes1(uint8(value >> 24));
        //        out[offset + 1] = bytes1(uint8(value >> 16));
        //        out[offset + 2] = bytes1(uint8(value >> 8));
        //        out[offset + 3] = bytes1(uint8(value));
        //
        //        unchecked {
        //            return offset + UINT32_BYTES_LENGTH;
        //        }
    }

    function writeUint64(
        bytes memory out,
        uint256 offset,
        uint64 value
    ) private pure returns (uint256) {
        assembly {
            let ptr := add(out, offset)
            mstore8(ptr, shr(56, value))
            mstore8(add(ptr, 1), shr(48, value))
            mstore8(add(ptr, 2), shr(40, value))
            mstore8(add(ptr, 3), shr(32, value))
            mstore8(add(ptr, 4), shr(24, value))
            mstore8(add(ptr, 5), shr(16, value))
            mstore8(add(ptr, 6), shr(8, value))
            mstore8(add(ptr, 7), value)
        }

        return offset + UINT64_BYTES_LENGTH;

        //        out[offset    ] = bytes1(uint8(value >> 56));
        //        out[offset + 1] = bytes1(uint8(value >> 48));
        //        out[offset + 2] = bytes1(uint8(value >> 40));
        //        out[offset + 3] = bytes1(uint8(value >> 32));
        //        out[offset + 4] = bytes1(uint8(value >> 24));
        //        out[offset + 5] = bytes1(uint8(value >> 16));
        //        out[offset + 6] = bytes1(uint8(value >> 8));
        //        out[offset + 7] = bytes1(uint8(value));
        //        unchecked { return offset + UINT64_BYTES_LENGTH; }
    }

    function writeAddress(
        bytes memory out,
        uint256 offset,
        address value
    ) private pure returns (uint256) {
        assembly {
            mstore(add(out, offset), value)
        }
        return offset + BYTES32_BYTES_LENGTH;

        //        for (uint256 i = 0; i < 32; ++i) {
        //            out[offset + i] = value[i];
        //        }
        //        unchecked { return offset + 32; }
    }

    function writeLenAndBytes(
        bytes memory out,
        uint256 offset,
        bytes memory data
    ) private pure returns (uint256) {
        // TODO: validate lengths
        offset = writeUint32(out, offset, uint32(data.length));
        return writeBytes(out, offset, data);
    }

    function writeBytes(
        bytes memory out,
        uint256 offset,
        bytes memory src
    ) private pure returns (uint256) {
        uint256 srcLen = src.length;
        if (srcLen == 0) return offset;

        assembly {
            let dstPtr := add(out, offset)
            let srcPtr := add(src, 32)

            for {
                let end := add(srcPtr, and(not(31), srcLen))
            } lt(srcPtr, end) {
                srcPtr := add(srcPtr, 32)
                dstPtr := add(dstPtr, 32)
            } {
                mstore(dstPtr, mload(srcPtr))
            }

            let rem := and(srcLen, 31)
            if rem {
                let mask := sub(shl(mul(8, sub(32, rem)), 1), 1)
                let srcWord := mload(srcPtr)
                let dstWord := mload(dstPtr)
                mstore(dstPtr, or(and(dstWord, mask), and(srcWord, not(mask))))
                dstPtr := add(dstPtr, rem)
            }
            offset := sub(dstPtr, out)
        }
        return offset + srcLen;

        //        for (uint256 i; i < src.length;++i) {
        //            out[i + offset] = src[i];
        //        }
        //        return offset + src.length;
    }

    function writeNestedBytes(
        bytes memory out,
        uint256 offset,
        bytes[] memory arr
    ) private pure returns (uint256) {
        offset = writeUint32(out, offset, uint32(arr.length));
        for (uint256 i; i < arr.length; ++i) {
            offset = writeUint32(out, offset, uint32(arr[i].length));
            offset = writeBytes(out, offset, arr[i]);
        }
        return offset;
    }

    function calculateNestedBytesLength(bytes[] memory data) internal pure returns (uint256) {
        uint256 length;
        for (uint256 i; i < data.length; ++i) {
            length += data[i].length + DEFAULT_BYTES_LENGTH;
        }
        return length;
    }
}
