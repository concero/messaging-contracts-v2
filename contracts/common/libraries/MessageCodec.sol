// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";
import {IRelayer} from "../../interfaces/IRelayer.sol";

library MessageCodec {
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
        uint256 srcChainDataOffset = SRC_CHAIN_DATA_OFFSET + LENGTH_BYTES_SIZE;
        uint256 start = srcChainDataOffset + ADDRESS_BYTES_LENGTH;

        return (
            address(bytes20(data[srcChainDataOffset:start])),
            uint64(
                bytes8(data[start:srcChainDataOffset + ADDRESS_BYTES_LENGTH + UINT64_BYTES_LENGTH])
            )
        );
    }

    function evmDstChainData(bytes calldata data) internal pure returns (address, uint32) {
        uint256 dstChainDataOffset = getDstChainDataOffset(data) + LENGTH_BYTES_SIZE;
        uint256 addressEnd = dstChainDataOffset + ADDRESS_BYTES_LENGTH;

        return (
            address(bytes20(data[dstChainDataOffset:addressEnd])),
            uint32(bytes4(data[addressEnd:addressEnd + UINT32_BYTES_LENGTH]))
        );
    }

    function relayerConfig(bytes calldata data) internal pure returns (bytes memory) {
        uint256 relayerConfigLengthOffset = getRelayerConfigOffset(data);
        uint256 start = relayerConfigLengthOffset + LENGTH_BYTES_SIZE;
        return
            data[start:start +
                uint24(
                    bytes3(
                        data[relayerConfigLengthOffset:relayerConfigLengthOffset +
                            UINT24_BYTES_LENGTH]
                    )
                )];
    }

    function validatorConfigs(bytes calldata data) internal pure returns (bytes[] memory) {
        return unflatBytes(data, getValidatorConfigsOffset(data));
    }

    function payload(bytes calldata data) internal pure returns (bytes memory) {
        uint256 payloadLengthOffset = getPayloadOffset(data);
        uint256 start = payloadLengthOffset + LENGTH_BYTES_SIZE;

        return data[start:start + uint24(bytes3(data[payloadLengthOffset:start]))];
    }

    // OFFSETS CALCULATION

    function getDstChainDataOffset(bytes calldata data) internal pure returns (uint256) {
        return
            SRC_CHAIN_DATA_OFFSET +
            LENGTH_BYTES_SIZE +
            uint24(bytes3(data[SRC_CHAIN_DATA_OFFSET:SRC_CHAIN_DATA_OFFSET + LENGTH_BYTES_SIZE]));
    }

    function getRelayerConfigOffset(bytes calldata data) internal pure returns (uint256) {
        uint256 dstRelayerLibOffset = getDstChainDataOffset(data);
        return
            dstRelayerLibOffset +
            uint24(bytes3(data[dstRelayerLibOffset:dstRelayerLibOffset + LENGTH_BYTES_SIZE])) +
            LENGTH_BYTES_SIZE;
    }

    function getValidatorConfigsOffset(bytes calldata data) internal pure returns (uint256) {
        uint256 relayerConfigOffset = getRelayerConfigOffset(data);
        return
            relayerConfigOffset +
            uint24(bytes3(data[relayerConfigOffset:relayerConfigOffset + LENGTH_BYTES_SIZE])) +
            LENGTH_BYTES_SIZE;
    }

    function getPayloadOffset(bytes calldata data) internal pure returns (uint256) {
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
        bytes calldata data,
        uint256 start
    ) internal pure returns (uint256) {
        uint256 nestedArrLength = uint24(bytes3(data[start:start + LENGTH_BYTES_SIZE]));
        uint256 offset = start + LENGTH_BYTES_SIZE;

        for (uint256 i; i < nestedArrLength; ++i) {
            offset += LENGTH_BYTES_SIZE + uint24(bytes3(data[offset:offset + LENGTH_BYTES_SIZE]));
        }

        return offset;
    }

    function unflatBytes(
        bytes calldata data,
        uint256 start
    ) internal pure returns (bytes[] memory) {
        bytes[] memory res = new bytes[](uint24(bytes3(data[start:start + LENGTH_BYTES_SIZE])));

        uint256 offset = start + LENGTH_BYTES_SIZE;
        for (uint256 i; i < res.length; ++i) {
            uint256 length = uint24(bytes3(data[offset:offset + LENGTH_BYTES_SIZE]));
            offset += LENGTH_BYTES_SIZE;
            res[i] = data[offset:offset + length];
            offset += length;
        }

        return res;
    }
}
