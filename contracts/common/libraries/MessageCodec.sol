// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";
import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";
import {IRelayer} from "../../interfaces/IRelayer.sol";
import {BytesUtils} from "./BytesUtils.sol";

library MessageCodec {
    using Bytes for bytes;
    using BytesUtils for bytes;

    error InvalidLength();

    uint8 internal constant UINT8_BYTES_LENGTH = 1;
    uint8 internal constant UINT24_BYTES_LENGTH = 3;
    uint8 internal constant UINT32_BYTES_LENGTH = 4;
    uint8 internal constant UINT64_BYTES_LENGTH = 8;
    uint8 internal constant BYTES32_BYTES_LENGTH = 32;
    uint8 internal constant ADDRESS_BYTES_LENGTH = 20;
    uint8 internal constant LENGTH_BYTES_SIZE = UINT24_BYTES_LENGTH;
    uint24 internal constant EVM_SRC_CHAIN_DATA_LENGTH = ADDRESS_BYTES_LENGTH + UINT64_BYTES_LENGTH;
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
        uint256 _nonce
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
                    EVM_SRC_CHAIN_DATA_LENGTH,
                    abi.encodePacked(msgSender, messageRequest.srcBlockConfirmations)
                ),
                abi.encodePacked(
                    uint24(messageRequest.dstChainData.length),
                    messageRequest.dstChainData,
                    uint24(messageRequest.relayerConfig.length),
                    messageRequest.relayerConfig,
                    flatBytes(messageRequest.validatorConfigs),
                    uint24(messageRequest.payload.length),
                    messageRequest.payload
                )
            );
    }

    function encodeEvmDstChainData(
        address receiver,
        uint32 dstGasLimit
    ) internal pure returns (bytes memory) {
        require(receiver != address(0), IRelayer.InvalidReceiver());
        require(dstGasLimit > 0, IConceroRouter.InvalidGasLimit());

        return abi.encodePacked(receiver, dstGasLimit);
    }

    function encodeEvmDstValidatorLibs(
        address[] memory libs
    ) internal pure returns (bytes[] memory) {
        bytes[] memory res = new bytes[](libs.length);

        for (uint256 i; i < res.length; ++i) {
            res[i] = abi.encodePacked(libs[i]);
        }

        return res;
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
            data.readUint64(srcChainDataOffset + ADDRESS_BYTES_LENGTH)
        );
    }

    function evmDstChainData(bytes memory data) internal pure returns (address, uint32) {
        uint256 dstChainDataOffset = getDstChainDataOffset(data) + LENGTH_BYTES_SIZE;

        return (
            data.readAddress(dstChainDataOffset),
            data.readUint32(dstChainDataOffset + ADDRESS_BYTES_LENGTH)
        );
    }

    function relayerConfig(bytes memory data) internal pure returns (bytes memory) {
        uint256 relayerConfigLengthOffset = getRelayerConfigOffset(data);
        uint256 start = relayerConfigLengthOffset + LENGTH_BYTES_SIZE;
        return data.slice(start, start + data.readUint24(relayerConfigLengthOffset));
    }

    function validatorConfigs(bytes memory data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getValidatorConfigsOffset(data));
    }

    function payload(bytes memory data) internal pure returns (bytes memory) {
        uint256 payloadLengthOffset = getPayloadOffset(data);
        uint256 start = payloadLengthOffset + LENGTH_BYTES_SIZE;
        return data.slice(start, start + data.readUint24(payloadLengthOffset));
    }

    // OFFSETS CALCULATION

    function getDstChainDataOffset(bytes memory data) internal pure returns (uint256) {
        return SRC_CHAIN_DATA_OFFSET + LENGTH_BYTES_SIZE + data.readUint24(SRC_CHAIN_DATA_OFFSET);
    }

    function getRelayerConfigOffset(bytes memory data) internal pure returns (uint256) {
        uint256 dstRelayerLibOffset = getDstChainDataOffset(data);
        return dstRelayerLibOffset + data.readUint24(dstRelayerLibOffset) + LENGTH_BYTES_SIZE;
    }

    function getValidatorConfigsOffset(bytes memory data) internal pure returns (uint256) {
        uint256 relayerConfigOffset = getRelayerConfigOffset(data);
        return relayerConfigOffset + data.readUint24(relayerConfigOffset) + LENGTH_BYTES_SIZE;
    }

    function getPayloadOffset(bytes memory data) internal pure returns (uint256) {
        return calculateNestedArrOffset(data, getValidatorConfigsOffset(data));
    }

    // GENERIC FUNCTIONS

    function flatBytes(bytes[] memory data) internal pure returns (bytes memory) {
        bytes memory res = abi.encodePacked(uint24(data.length));

        for (uint256 i; i < data.length; ++i) {
            res = abi.encodePacked(res, uint24(data[i].length), data[i]);
        }

        return res;
    }

    function calculateNestedArrOffset(
        bytes memory data,
        uint256 start
    ) internal pure returns (uint256) {
        uint256 nestedArrLength = data.readUint24(start);
        uint256 offset = start + LENGTH_BYTES_SIZE;

        for (uint256 i; i < nestedArrLength; ++i) {
            offset += LENGTH_BYTES_SIZE + data.readUint24(offset);
        }

        return offset;
    }

    function unflatBytes(bytes memory data, uint256 start) internal pure returns (bytes[] memory) {
        bytes[] memory res = new bytes[](data.readUint24(start));

        uint256 offset = start + LENGTH_BYTES_SIZE;
        for (uint256 i; i < res.length; ++i) {
            uint256 length = data.readUint24(offset);
            offset += LENGTH_BYTES_SIZE;
            res[i] = data.slice(offset, offset + length);
            offset += length;
        }

        return res;
    }
}
