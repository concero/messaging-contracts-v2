// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";
import {IRelayer} from "../../interfaces/IRelayer.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {CodecCommon} from "./CodecCommon.sol";

library MessageCodec {
    using SafeCast for uint256;

    uint8 internal constant VERSION = 1;

    uint24 internal constant EVM_SRC_CHAIN_DATA_LENGTH =
        CodecCommon.ADDRESS_BYTES_LENGTH + CodecCommon.UINT64_BYTES_LENGTH;

    uint8 internal constant SRC_CHAIN_SELECTOR_OFFSET = CodecCommon.UINT8_BYTES_LENGTH;
    uint8 internal constant DST_CHAIN_SELECTOR_OFFSET =
        SRC_CHAIN_SELECTOR_OFFSET + CodecCommon.UINT24_BYTES_LENGTH; // 4
    uint8 internal constant NONCE_OFFSET =
        DST_CHAIN_SELECTOR_OFFSET + CodecCommon.UINT24_BYTES_LENGTH;
    uint8 internal constant SRC_CHAIN_DATA_OFFSET = NONCE_OFFSET + CodecCommon.BYTES32_BYTES_LENGTH;

    // WRITE FUNCTIONS //

    function toMessageReceiptBytes(
        IConceroRouter.MessageRequest memory messageRequest,
        uint24 _srcChainSelector,
        address msgSender,
        uint256 _nonce,
        bytes[] memory internalValidatorConfigs
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                abi.encodePacked(
                    VERSION, // 0
                    _srcChainSelector, // 1
                    messageRequest.dstChainSelector, // 4
                    _nonce,
                    EVM_SRC_CHAIN_DATA_LENGTH,
                    abi.encodePacked(msgSender, messageRequest.srcBlockConfirmations)
                ),
                abi.encodePacked(
                    messageRequest.dstChainData.length.toUint24(),
                    messageRequest.dstChainData,
                    messageRequest.relayerConfig.length.toUint24(),
                    messageRequest.relayerConfig,
                    flatBytes(messageRequest.validatorConfigs),
                    flatBytes(internalValidatorConfigs),
                    messageRequest.payload.length.toUint24(),
                    messageRequest.payload
                )
            );
    }

    function encodeEvmDstChainData(
        address receiver,
        uint32 dstGasLimit
    ) internal pure returns (bytes memory) {
        require(receiver != address(0), IRelayer.InvalidReceiver());

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

    function version(bytes calldata data) internal pure returns (uint8) {
        return uint8(bytes1(data[0:SRC_CHAIN_SELECTOR_OFFSET]));
    }

    function srcChainSelector(bytes calldata data) internal pure returns (uint24) {
        return uint24(bytes3(data[SRC_CHAIN_SELECTOR_OFFSET:DST_CHAIN_SELECTOR_OFFSET]));
    }

    function dstChainSelector(bytes calldata data) internal pure returns (uint24) {
        return uint24(bytes3(data[DST_CHAIN_SELECTOR_OFFSET:NONCE_OFFSET]));
    }

    function nonce(bytes calldata data) internal pure returns (uint256) {
        return uint256(bytes32(data[NONCE_OFFSET:SRC_CHAIN_DATA_OFFSET]));
    }

    function evmSrcChainData(bytes calldata data) internal pure returns (address, uint64) {
        uint256 srcChainDataOffset = SRC_CHAIN_DATA_OFFSET + CodecCommon.LENGTH_BYTES_SIZE;
        uint256 start = srcChainDataOffset + CodecCommon.ADDRESS_BYTES_LENGTH;

        return (
            address(bytes20(data[srcChainDataOffset:start])),
            uint64(
                bytes8(
                    data[start:srcChainDataOffset +
                        CodecCommon.ADDRESS_BYTES_LENGTH +
                        CodecCommon.UINT64_BYTES_LENGTH]
                )
            )
        );
    }

    function evmDstChainData(bytes calldata data) internal pure returns (address, uint32) {
        uint256 dstChainDataOffset = getDstChainDataOffset(data) + CodecCommon.LENGTH_BYTES_SIZE;
        uint256 addressEnd = dstChainDataOffset + CodecCommon.ADDRESS_BYTES_LENGTH;

        return (
            address(bytes20(data[dstChainDataOffset:addressEnd])),
            uint32(bytes4(data[addressEnd:addressEnd + CodecCommon.UINT32_BYTES_LENGTH]))
        );
    }

    function relayerConfig(bytes calldata data) internal pure returns (bytes memory) {
        uint256 relayerConfigLengthOffset = getRelayerConfigOffset(data);
        uint256 start = relayerConfigLengthOffset + CodecCommon.LENGTH_BYTES_SIZE;
        return
            data[start:start +
                uint24(
                    bytes3(
                        data[relayerConfigLengthOffset:relayerConfigLengthOffset +
                            CodecCommon.UINT24_BYTES_LENGTH]
                    )
                )];
    }

    function validatorConfigs(bytes calldata data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getValidatorConfigsOffset(data));
    }

    function internalValidatorsConfig(bytes calldata data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getInternalValidatorConfigsOffset(data));
    }

    function payload(bytes calldata data) internal pure returns (bytes memory) {
        uint256 payloadLengthOffset = getPayloadOffset(data);
        uint256 start = payloadLengthOffset + CodecCommon.LENGTH_BYTES_SIZE;

        return data[start:start + uint24(bytes3(data[payloadLengthOffset:start]))];
    }

    function calldataPayload(bytes calldata data) internal pure returns (bytes calldata) {
        uint256 payloadLengthOffset = getPayloadOffset(data);
        uint256 start = payloadLengthOffset + CodecCommon.LENGTH_BYTES_SIZE;

        return data[start:start + uint24(bytes3(data[payloadLengthOffset:start]))];
    }

    // DECODERS

    function decodeEvmDstChainData(
        bytes calldata dstChainData
    ) internal pure returns (address, uint32) {
        return (
            address(bytes20(dstChainData[0:CodecCommon.ADDRESS_BYTES_LENGTH])),
            uint32(
                bytes4(
                    dstChainData[CodecCommon.ADDRESS_BYTES_LENGTH:CodecCommon.ADDRESS_BYTES_LENGTH +
                        CodecCommon.UINT32_BYTES_LENGTH]
                )
            )
        );
    }

    // OFFSETS CALCULATION

    function getDstChainDataOffset(bytes calldata data) internal pure returns (uint256) {
        return
            SRC_CHAIN_DATA_OFFSET +
            CodecCommon.LENGTH_BYTES_SIZE +
            uint24(
                bytes3(
                    data[SRC_CHAIN_DATA_OFFSET:SRC_CHAIN_DATA_OFFSET +
                        CodecCommon.LENGTH_BYTES_SIZE]
                )
            );
    }

    function getRelayerConfigOffset(bytes calldata data) internal pure returns (uint256) {
        uint256 dstRelayerLibOffset = getDstChainDataOffset(data);
        return
            dstRelayerLibOffset +
            uint24(
                bytes3(
                    data[dstRelayerLibOffset:dstRelayerLibOffset + CodecCommon.LENGTH_BYTES_SIZE]
                )
            ) +
            CodecCommon.LENGTH_BYTES_SIZE;
    }

    function getValidatorConfigsOffset(bytes calldata data) internal pure returns (uint256) {
        uint256 relayerConfigOffset = getRelayerConfigOffset(data);
        return
            relayerConfigOffset +
            uint24(
                bytes3(
                    data[relayerConfigOffset:relayerConfigOffset + CodecCommon.LENGTH_BYTES_SIZE]
                )
            ) +
            CodecCommon.LENGTH_BYTES_SIZE;
    }

    function getInternalValidatorConfigsOffset(
        bytes calldata data
    ) internal pure returns (uint256) {
        return calculateNestedArrOffset(data, getValidatorConfigsOffset(data));
    }

    function getPayloadOffset(bytes calldata data) internal pure returns (uint256) {
        return calculateNestedArrOffset(data, getInternalValidatorConfigsOffset(data));
    }

    // GENERIC FUNCTIONS

    function flatBytes(bytes[] memory data) internal pure returns (bytes memory) {
        bytes memory res = abi.encodePacked(data.length.toUint24());

        for (uint256 i; i < data.length; ++i) {
            res = abi.encodePacked(res, data[i].length.toUint24(), data[i]);
        }

        return res;
    }

    function calculateNestedArrOffset(
        bytes calldata data,
        uint256 start
    ) internal pure returns (uint256) {
        uint256 nestedArrLength = uint24(bytes3(data[start:start + CodecCommon.LENGTH_BYTES_SIZE]));
        uint256 offset = start + CodecCommon.LENGTH_BYTES_SIZE;

        for (uint256 i; i < nestedArrLength; ++i) {
            offset +=
                CodecCommon.LENGTH_BYTES_SIZE +
                uint24(bytes3(data[offset:offset + CodecCommon.LENGTH_BYTES_SIZE]));
        }

        return offset;
    }

    function unflatBytes(
        bytes calldata data,
        uint256 start
    ) internal pure returns (bytes[] memory) {
        bytes[] memory res = new bytes[](
            uint24(bytes3(data[start:start + CodecCommon.LENGTH_BYTES_SIZE]))
        );

        uint256 offset = start + CodecCommon.LENGTH_BYTES_SIZE;
        for (uint256 i; i < res.length; ++i) {
            uint256 length = uint24(bytes3(data[offset:offset + CodecCommon.LENGTH_BYTES_SIZE]));
            offset += CodecCommon.LENGTH_BYTES_SIZE;
            res[i] = data[offset:offset + length];
            offset += length;
        }

        return res;
    }
}
