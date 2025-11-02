// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";
import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";
import {BytesUtils} from "./BytesUtils.sol";

library MessageCodec {
    using Bytes for bytes;
    using BytesUtils for bytes;

    uint8 internal constant UINT8_BYTES_LENGTH = 1;
    uint8 internal constant UINT24_BYTES_LENGTH = 3;
    uint8 internal constant UINT32_BYTES_LENGTH = 4;
    uint8 internal constant UINT64_BYTES_LENGTH = 8;
    uint8 internal constant BYTES32_BYTES_LENGTH = 32;
    uint8 internal constant ADDRESS_BYTES_LENGTH = 20;
    uint8 internal constant LENGTH_BYTES_SIZE = UINT32_BYTES_LENGTH;
    uint8 internal constant EVM_SRC_CHAIN_DATA_LENGTH = BYTES32_BYTES_LENGTH + UINT64_BYTES_LENGTH;
    uint8 internal constant VERSION = 1;

    uint8 internal constant SRC_CHAIN_SELECTOR_OFFSET = 1;
    uint8 internal constant DST_CHAIN_SELECTOR_OFFSET =
        SRC_CHAIN_SELECTOR_OFFSET + UINT24_BYTES_LENGTH; // 4
    uint8 internal constant NONCE_OFFSET = DST_CHAIN_SELECTOR_OFFSET + UINT24_BYTES_LENGTH;
    uint8 internal constant SRC_CHAIN_DATA_OFFSET = NONCE_OFFSET + BYTES32_BYTES_LENGTH;

    // WRITE FUNCTIONS //
    function toMessageReceiptBytes(
        IConceroRouter.MessageRequest memory messageRequest,
        uint24 _srcChainSelector,
        address msgSender,
        uint256 _nonce,
        bytes memory dstRelayerLib,
        bytes[] memory dstValidatorLibs
    ) internal pure returns (bytes memory) {
        // TODO: validate all lengths

        return
            abi.encodePacked(
                abi.encodePacked(
                    VERSION, // 0
                    _srcChainSelector, // 1
                    messageRequest.dstChainSelector, // 4
                    _nonce,
                    // src chain data
                    uint32(EVM_SRC_CHAIN_DATA_LENGTH),
                    abi.encodePacked(
                        bytes32(bytes20(msgSender)),
                        messageRequest.srcBlockConfirmations
                    ),
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

    function encodeEvmDstChainData(
        address receiver,
        uint32 dstGasLimit
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(bytes32(bytes20(receiver)), dstGasLimit);
    }

    // READ FUNCTIONS //

    function version(bytes memory data) internal pure returns (uint8) {
        return data.readUint8(0);
    }

    function srcChainSelector(bytes memory data) internal pure returns (uint24) {
        return data.readUint24(SRC_CHAIN_SELECTOR_OFFSET);
    }

    function dstChainSelector(bytes memory data) internal pure returns (uint24) {
        return data.readUint24(DST_CHAIN_SELECTOR_OFFSET);
    }

    function nonce(bytes memory data) internal pure returns (uint256) {
        return data.readUint256(NONCE_OFFSET);
    }

    function evmSrcChainData(bytes memory data) internal pure returns (address, uint64) {
        uint256 srcChainDataOffset = SRC_CHAIN_DATA_OFFSET + LENGTH_BYTES_SIZE;
        return (
            data.readAddress(srcChainDataOffset),
            data.readUint64(srcChainDataOffset + BYTES32_BYTES_LENGTH)
        );
    }

    function evmDstChainData(bytes memory data) internal pure returns (address, uint32) {
        uint256 dstChainDataOffset = getDstChainDataOffset(data) + LENGTH_BYTES_SIZE;

        return (
            data.readAddress(dstChainDataOffset),
            data.readUint32(dstChainDataOffset + BYTES32_BYTES_LENGTH)
        );
    }

    function emvDstRelayerLib(bytes memory data) internal pure returns (address) {
        return data.readAddress(getDstRelayerLibOffset(data) + LENGTH_BYTES_SIZE);
    }

    function relayerConfig(bytes memory data) internal pure returns (bytes memory) {
        uint256 relayerConfigLengthOffset = getRelayerConfigOffset(data);
        uint256 start = relayerConfigLengthOffset + LENGTH_BYTES_SIZE;
        return data.slice(start, start + data.readUint32(relayerConfigLengthOffset));
    }

    function evmDstValidatorLibs(bytes memory data) internal pure returns (address[] memory) {
        uint256 dstValidatorLibsOffset = getDstValidatorLibsOffset(data);
        address[] memory res = new address[](data.readUint32(dstValidatorLibsOffset));

        uint256 offset = dstValidatorLibsOffset + LENGTH_BYTES_SIZE;
        for (uint256 i; i < res.length; ++i) {
            uint256 length = data.readUint32(offset);
            offset += LENGTH_BYTES_SIZE;
            res[i] = data.readAddress(offset);
            offset += length;
        }

        return res;
    }

    function validatorConfigs(bytes memory data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getValidatorConfigsOffset(data));
    }

    function validationRpcs(bytes memory data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getValidationRpcsOffset(data));
    }

    function deliveryRpcs(bytes memory data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getDeliveryRpcsOffset(data));
    }

    function payload(bytes memory data) internal pure returns (bytes memory) {
        uint256 payloadLengthOffset = getPayloadOffset(data);
        uint256 start = payloadLengthOffset + LENGTH_BYTES_SIZE;
        return data.slice(start, start + data.readUint32(payloadLengthOffset));
    }

    // OFFSETS CALCULATION

    function getDstChainDataOffset(bytes memory data) internal pure returns (uint256) {
        return SRC_CHAIN_DATA_OFFSET + LENGTH_BYTES_SIZE + data.readUint32(SRC_CHAIN_DATA_OFFSET);
    }

    function getDstRelayerLibOffset(bytes memory data) internal pure returns (uint256) {
        uint256 dstChainDataOffset = getDstChainDataOffset(data);
        return dstChainDataOffset + data.readUint32(dstChainDataOffset) + LENGTH_BYTES_SIZE;
    }

    function getRelayerConfigOffset(bytes memory data) internal pure returns (uint256) {
        uint256 dstRelayerLibOffset = getDstRelayerLibOffset(data);
        return dstRelayerLibOffset + data.readUint32(dstRelayerLibOffset) + LENGTH_BYTES_SIZE;
    }

    function getDstValidatorLibsOffset(bytes memory data) internal pure returns (uint256) {
        uint256 relayerConfigOffset = getRelayerConfigOffset(data);
        return relayerConfigOffset + data.readUint32(relayerConfigOffset) + LENGTH_BYTES_SIZE;
    }

    function getValidatorConfigsOffset(bytes memory data) internal pure returns (uint256) {
        return calculateNestedArrOffset(data, getDstValidatorLibsOffset(data));
    }

    function getValidationRpcsOffset(bytes memory data) internal pure returns (uint256) {
        return calculateNestedArrOffset(data, getValidatorConfigsOffset(data));
    }

    function getDeliveryRpcsOffset(bytes memory data) internal pure returns (uint256) {
        return calculateNestedArrOffset(data, getValidationRpcsOffset(data));
    }

    function getPayloadOffset(bytes memory data) internal pure returns (uint256) {
        return calculateNestedArrOffset(data, getDeliveryRpcsOffset(data));
    }

    // GENERIC FUNCTIONS //

    function flatBytes(bytes[] memory data) internal pure returns (bytes memory) {
        uint256 totalLength = UINT32_BYTES_LENGTH;

        for (uint256 i; i < data.length; ++i) {
            totalLength += data[i].length + UINT32_BYTES_LENGTH;
        }

        bytes memory res = new bytes(totalLength);
        uint256 j;

        res.writeUint32(j, uint32(data.length));
        j += UINT32_BYTES_LENGTH;

        for (uint256 i; i < data.length; ++i) {
            res.writeUint32(j, uint32(data[i].length));
            j += UINT32_BYTES_LENGTH;

            for (uint256 k; k < data[i].length; ++k) {
                res[j] = data[i][k];
                ++j;
            }
        }

        return res;
    }

    function calculateNestedArrOffset(
        bytes memory data,
        uint256 start
    ) internal pure returns (uint256) {
        uint256 nestedArrLength = data.readUint32(start);
        uint256 offset = start + LENGTH_BYTES_SIZE;

        for (uint256 i; i < nestedArrLength; ++i) {
            offset += LENGTH_BYTES_SIZE + data.readUint32(offset);
        }

        return offset;
    }

    function unflatBytes(bytes memory data, uint256 start) internal pure returns (bytes[] memory) {
        bytes[] memory res = new bytes[](data.readUint32(start));

        uint256 offset = start + LENGTH_BYTES_SIZE;
        for (uint256 i; i < res.length; ++i) {
            uint256 length = data.readUint32(offset);
            offset += LENGTH_BYTES_SIZE;
            res[i] = data.slice(offset, offset + length);
            offset += length;
        }

        return res;
    }
}
