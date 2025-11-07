// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import "../../../contracts/common/libraries/MessageCodec.sol";

contract MessageCodecCertoraHarness {
    function toMessageReceiptBytes(
        IConceroRouter.MessageRequest memory messageRequest,
        uint24 _srcChainSelector,
        address msgSender,
        uint256 _nonce,
        bytes memory dstRelayerLib,
        bytes[] memory dstValidatorLibs
    ) external pure returns (bytes memory) {
        return
            MessageCodec.toMessageReceiptBytes(
                messageRequest,
                _srcChainSelector,
                msgSender,
                _nonce,
                dstRelayerLib,
                dstValidatorLibs
            );
    }

    function encodeEvmDstChainData(
        address receiver,
        uint32 dstGasLimit
    ) external pure returns (bytes memory) {
        return MessageCodec.encodeEvmDstChainData(receiver, dstGasLimit);
    }

    function version(bytes memory data) external pure returns (uint8) {
        return MessageCodec.version(data);
    }

    function srcChainSelector(bytes memory data) external pure returns (uint24) {
        return MessageCodec.srcChainSelector(data);
    }

    function dstChainSelector(bytes memory data) external pure returns (uint24) {
        return MessageCodec.dstChainSelector(data);
    }

    function nonce(bytes memory data) external pure returns (uint256) {
        return MessageCodec.nonce(data);
    }

    function evmSrcChainData(bytes memory data) external pure returns (address, uint64) {
        return MessageCodec.evmSrcChainData(data);
    }

    function evmDstChainData(bytes memory data) external pure returns (address, uint32) {
        return MessageCodec.evmDstChainData(data);
    }

    function emvDstRelayerLib(bytes memory data) external pure returns (address) {
        return MessageCodec.emvDstRelayerLib(data);
    }

    function relayerConfig(bytes memory data) external pure returns (bytes memory) {
        return MessageCodec.relayerConfig(data);
    }

    function evmDstValidatorLibs(bytes memory data) external pure returns (address[] memory) {
        return MessageCodec.evmDstValidatorLibs(data);
    }

    function validatorConfigs(bytes memory data) external pure returns (bytes[] memory) {
        return MessageCodec.validatorConfigs(data);
    }

    function validationRpcs(bytes memory data) external pure returns (bytes[] memory) {
        return MessageCodec.validationRpcs(data);
    }

    function deliveryRpcs(bytes memory data) external pure returns (bytes[] memory) {
        return MessageCodec.deliveryRpcs(data);
    }

    function payload(bytes memory data) external pure returns (bytes memory) {
        return MessageCodec.payload(data);
    }
}
