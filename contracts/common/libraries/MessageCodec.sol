// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import "forge-std/src/console.sol";
import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

library MessageCodec {
    uint8 internal constant UINT8_BYTES_LENGTH = 1;
    uint8 internal constant UINT24_BYTES_LENGTH = 3;
    uint8 internal constant UINT32_BYTES_LENGTH = 4;
    uint8 internal constant UINT64_BYTES_LENGTH = 8;
    uint8 internal constant BYTES32_BYTES_LENGTH = 32;
    uint8 internal constant ADDRESS_BYTES_LENGTH = 20;
    uint8 internal constant VERSION = 1;

    function toMessageReceiptBytes(
        IConceroRouter.MessageRequest memory messageRequest,
        uint24 srcChainSelector,
        address msgSender,
        bytes memory dstRelayerLib,
        bytes[] memory dstValidatorLibs
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                abi.encodePacked(
                    VERSION,
                    srcChainSelector,
                    messageRequest.dstChainSelector,
                    uint64(messageRequest.srcBlockConfirmations),
                    bytes32(uint256(uint160(msgSender))),
                    uint32(messageRequest.dstChainData.length),
                    messageRequest.dstChainData,
                    uint32(dstRelayerLib.length),
                    dstRelayerLib
                ),
                abi.encodePacked(
                    uint32(messageRequest.relayerConfig.length),
                    messageRequest.relayerConfig,
                    flatBytes(dstValidatorLibs),
                    flatBytes(messageRequest.validatorConfigs),
                    flatBytes(messageRequest.validationRpcs),
                    flatBytes(messageRequest.deliveryRpcs),
                    uint32(messageRequest.payload.length),
                    messageRequest.payload
                )
            );
    }

    function flatBytes(bytes[] memory data) internal pure returns (bytes memory) {
        uint256 totalLength = UINT32_BYTES_LENGTH;

        for (uint256 i; i < data.length; ++i) {
            totalLength += data[i].length + UINT32_BYTES_LENGTH;
        }

        bytes memory res = new bytes(totalLength);
        uint256 j;

        writeUint32(res, j, uint32(data.length));
        j += UINT32_BYTES_LENGTH;

        for (uint256 i; i < data.length; ++i) {
            writeUint32(res, j, uint32(data[i].length));
            j += UINT32_BYTES_LENGTH;

            for (uint256 k; k < data[i].length; ++k) {
                res[j] = data[i][k];
                ++j;
            }
        }

        return res;
    }

    //    function toMessageReceipt(
    //        bytes memory packedMessageReceipt
    //    ) internal pure returns (IConceroRouter.MessageReceipt memory) {
    //        IConceroRouter.MessageReceipt memory messageReceipt = IConceroRouter.MessageReceipt();
    //
    //        uint256 offset = 32;
    //
    //        messageReceipt.srcChainSelector = readUint24(packedMessageReceipt, offset);
    //        offset += UINT24_BYTES_LENGTH;
    //        messageReceipt.dstChainSelector = readUint24(packedMessageReceipt, offset);
    //        offset += UINT24_BYTES_LENGTH;
    //        messageReceipt.srcChainData;
    //
    //        return messageReceipt;
    //    }

    function writeUint32(
        bytes memory out,
        uint256 offset,
        uint32 value
    ) private pure returns (uint256) {
        assembly {
            let ptr := add(add(out, 32), offset)
            mstore8(ptr, shr(24, value))
            mstore8(add(ptr, 1), shr(16, value))
            mstore8(add(ptr, 2), shr(8, value))
            mstore8(add(ptr, 3), value)
        }

        return offset + UINT32_BYTES_LENGTH;
    }

    function calculateNestedBytesLength(bytes[] memory data) internal pure returns (uint256) {
        uint256 length;
        for (uint256 i; i < data.length; ++i) {
            length += data[i].length + UINT32_BYTES_LENGTH;
        }
        return length;
    }
}
