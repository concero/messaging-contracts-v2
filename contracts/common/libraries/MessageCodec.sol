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

/// @title MessageCodec
/// @notice Library for encoding and decoding Concero cross-chain message receipts and related data.
/// @dev
/// - Defines a binary format for message receipts, destination chain data, and nested arrays.
/// - Used by Concero router and clients to construct, parse, and interpret cross-chain messages.
/// - Relies on fixed offsets and compact length-prefix encoding for efficiency.
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

    /// @notice Encodes a `MessageRequest` plus metadata into a packed message receipt.
    /// @dev
    /// Layout (high level):
    /// - [0]         : VERSION (uint8)
    /// - [1:4]       : srcChainSelector (uint24)
    /// - [4:7]       : dstChainSelector (uint24)
    /// - [7:39]      : nonce (bytes32)
    /// - [39:42]     : srcChainData length (uint24)
    /// - [42:..]     : srcChainData (sender address + srcBlockConfirmations)
    /// - [...]       : dstChainData length + bytes
    /// - [...]       : relayerConfig length + bytes
    /// - [...]       : validatorConfigs (flattened nested bytes array)
    /// - [...]       : internalValidatorConfigs (flattened nested bytes array)
    /// - [...]       : payload length + bytes
    ///
    /// The returned value is the canonical “message receipt” used by Concero.
    ///
    /// @param messageRequest Original message request from the sender.
    /// @param _srcChainSelector Chain selector of the source chain.
    /// @param msgSender Original `msg.sender` of the `conceroSend` call.
    /// @param _nonce Monotonically increasing nonce for (sender, src, dst) tuple.
    /// @param internalValidatorConfigs Per-validator internal configs used on the destination chain.
    /// @return Packed message receipt bytes.
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

    /// @notice Encodes destination chain data for an EVM receiver.
    /// @dev
    /// Layout:
    /// - [0:20] : receiver (address)
    /// - [20:24]: dstGasLimit (uint32)
    /// Reverts if `receiver` is the zero address.
    ///
    /// @param receiver Address of the receiving Concero client on the destination chain.
    /// @param dstGasLimit Gas limit to allocate for the receiver call.
    /// @return Encoded destination chain data bytes.
    function encodeEvmDstChainData(
        address receiver,
        uint32 dstGasLimit
    ) internal pure returns (bytes memory) {
        require(receiver != address(0), IRelayer.InvalidReceiver());

        return abi.encodePacked(receiver, dstGasLimit);
    }

    /// @notice Encodes an array of validator/relayer library addresses to raw bytes arrays.
    /// @dev Each address is packed into its own `bytes` element.
    /// Useful when composing validator libs data for inclusion in a message.
    ///
    /// @param libs Array of library addresses.
    /// @return res Array of `bytes` where each entry is `abi.encodePacked(libs[i])`.
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

    /// @notice Extracts the message receipt version byte.
    /// @param data Packed message receipt.
    /// @return Version identifier stored in the first byte.
    function version(bytes calldata data) internal pure returns (uint8) {
        return uint8(bytes1(data[0:SRC_CHAIN_SELECTOR_OFFSET]));
    }

    /// @notice Extracts the source chain selector from a message receipt.
    /// @param data Packed message receipt.
    /// @return Source chain selector as uint24.
    function srcChainSelector(bytes calldata data) internal pure returns (uint24) {
        return uint24(bytes3(data[SRC_CHAIN_SELECTOR_OFFSET:DST_CHAIN_SELECTOR_OFFSET]));
    }

    /// @notice Extracts the destination chain selector from a message receipt.
    /// @param data Packed message receipt.
    /// @return Destination chain selector as uint24.
    function dstChainSelector(bytes calldata data) internal pure returns (uint24) {
        return uint24(bytes3(data[DST_CHAIN_SELECTOR_OFFSET:NONCE_OFFSET]));
    }

    /// @notice Extracts the message nonce from a message receipt.
    /// @param data Packed message receipt.
    /// @return Nonce as uint256.
    function nonce(bytes calldata data) internal pure returns (uint256) {
        return uint256(bytes32(data[NONCE_OFFSET:SRC_CHAIN_DATA_OFFSET]));
    }

    /// @notice Extracts EVM source chain data (sender + confirmations) from the receipt.
    /// @dev
    /// EVM source chain data layout:
    /// - [0:20] : sender address
    /// - [20:28]: srcBlockConfirmations (uint64)
    ///
    /// @param data Packed message receipt.
    /// @return Source sender address and required block confirmations.
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

    /// @notice Extracts EVM destination chain data (receiver + gas limit) from the receipt.
    /// @dev Uses the embedded dstChainData length to locate the segment.
    ///
    /// @param data Packed message receipt.
    /// @return Receiver address and dstGasLimit in uint32.
    function evmDstChainData(bytes calldata data) internal pure returns (address, uint32) {
        uint256 dstChainDataOffset = getDstChainDataOffset(data) + CodecCommon.LENGTH_BYTES_SIZE;
        uint256 addressEnd = dstChainDataOffset + CodecCommon.ADDRESS_BYTES_LENGTH;

        return (
            address(bytes20(data[dstChainDataOffset:addressEnd])),
            uint32(bytes4(data[addressEnd:addressEnd + CodecCommon.UINT32_BYTES_LENGTH]))
        );
    }

    /// @notice Extracts the relayer configuration segment from the message receipt.
    /// @dev The relayer config is a length-prefixed bytes segment following dstChainData.
    ///
    /// @param data Packed message receipt.
    /// @return Relayer configuration bytes.
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

    /// @notice Extracts the validator configs array from the message receipt.
    /// @dev Uses nested length-prefix encoding (see `flatBytes` / `unflatBytes`).
    ///
    /// @param data Packed message receipt.
    /// @return Array of validator configuration blobs.
    function validatorConfigs(bytes calldata data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getValidatorConfigsOffset(data));
    }

    /// @notice Extracts internal validator configs array from the message receipt.
    /// @dev These configs are intended for use only on the destination chain.
    ///
    /// @param data Packed message receipt.
    /// @return Array of internal validator configuration blobs.
    function internalValidatorsConfig(bytes calldata data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getInternalValidatorConfigsOffset(data));
    }

    /// @notice Extracts the payload section as a dynamic bytes array (in memory).
    /// @dev The payload is stored as: length (uint24) + payload bytes.
    ///
    /// @param data Packed message receipt.
    /// @return Decoded payload bytes.
    function payload(bytes calldata data) internal pure returns (bytes memory) {
        uint256 payloadLengthOffset = getPayloadOffset(data);
        uint256 start = payloadLengthOffset + CodecCommon.LENGTH_BYTES_SIZE;

        return data[start:start + uint24(bytes3(data[payloadLengthOffset:start]))];
    }

    /// @notice Extracts the payload section as a calldata slice (zero-copy).
    /// @dev Same as `payload` but avoids allocating a new bytes array in memory.
    ///
    /// @param data Packed message receipt.
    /// @return Calldata slice pointing to the payload bytes.
    function calldataPayload(bytes calldata data) internal pure returns (bytes calldata) {
        uint256 payloadLengthOffset = getPayloadOffset(data);
        uint256 start = payloadLengthOffset + CodecCommon.LENGTH_BYTES_SIZE;

        return data[start:start + uint24(bytes3(data[payloadLengthOffset:start]))];
    }

    // DECODERS

    /// @notice Decodes EVM destination chain data from a raw dstChainData bytes blob.
    /// @dev This is the inverse of `encodeEvmDstChainData`.
    ///
    /// @param dstChainData Encoded destination chain data (receiver + gas limit).
    /// @return Receiver address and dstGasLimit as uint32.
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

    /// @notice Computes the starting offset of the dstChainData length prefix in the receipt.
    /// @param data Packed message receipt.
    /// @return Offset index where dstChainData length is stored.
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
