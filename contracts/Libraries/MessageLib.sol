// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ClientMessageRequest, EvmSrcChainData, InternalMessage, InternalMessageConfig, EvmDstChainData} from "../Common/MessageTypes.sol";
import {SupportedChains} from "./SupportedChains.sol";

library MessageLib {
    error InvalidMessageVersion(uint8 version);
    error InvalidDstChainData();
    error InvalidMessagePayload();
    error InvalidSrcChainData();
    error InvalidConfigVersion();
    error InvalidAdditionalRelayers();
    error InvalidMinSrcConfirmations();
    error InvalidMinDstConfirmations();
    error InvalidSrcChainSelector();
    error InvalidDstChainSelector();

    function buildInternalMessage(
        ClientMessageRequest memory req,
        bytes memory srcChainData,
        uint256 nonce
    ) internal view returns (InternalMessage memory) {
        validateMessageRequest(req);

        EvmSrcChainData memory decodedSrcChainData = abi.decode(srcChainData, (EvmSrcChainData));
        bytes32 messageId = buildMessageId(decodedSrcChainData.sender, nonce, req.messageConfig);

        return
            InternalMessage({
                messageConfig: req.messageConfig,
                messageId: messageId,
                srcChainData: srcChainData, // Store as bytes
                dstChainData: req.dstChainData,
                message: req.message
            });
    }
    function buildMessageId(
        address sender,
        uint256 nonce,
        uint256 messageConfig
    ) private view returns (bytes32) {
        return keccak256(abi.encodePacked(sender, nonce, block.number, messageConfig));
    }

    function validateMessageRequest(ClientMessageRequest memory req) internal pure {
        validateMessageConfig(req.messageConfig);
        require(req.dstChainData.length > 0, InvalidDstChainData());
    }

    function validateIncomingMessage(InternalMessage memory message) internal pure {
        validateMessageConfig(message.messageConfig);
        //        require(message.srcChainData.length > 0, InvalidSrcChainData());
        require(message.dstChainData.length > 0, InvalidDstChainData());
    }

    function validateMessageConfig(uint256 config) private pure {
        InternalMessageConfig memory decodedConfig = decodeMessageConfig(config);

        require(decodedConfig.version > 0, InvalidConfigVersion());
        require(decodedConfig.additionalRelayers <= 255, InvalidAdditionalRelayers());
        require(decodedConfig.minSrcConfirmations > 0, InvalidMinSrcConfirmations());
        require(decodedConfig.minDstConfirmations > 0, InvalidMinDstConfirmations());
        require(
            SupportedChains.isChainSupported(decodedConfig.srcChainSelector),
            InvalidSrcChainSelector()
        );
        require(
            SupportedChains.isChainSupported(decodedConfig.dstChainSelector),
            InvalidDstChainSelector()
        );
    }

    function decodeMessageConfig(
        uint256 config
    ) private pure returns (InternalMessageConfig memory) {
        return
            InternalMessageConfig({
                version: uint8(config >> 248),
                additionalRelayers: uint8(config >> 240),
                minSrcConfirmations: uint16(config >> 224),
                minDstConfirmations: uint16(config >> 208),
                srcChainSelector: uint24(config >> 184),
                dstChainSelector: uint24(config >> 160),
                isCallbackable: (config & (1 << 159)) != 0
            });
    }

    function decodeMessage(
        InternalMessage memory message
    )
        internal
        pure
        returns (
            InternalMessageConfig memory decodedMessageConfig,
            EvmSrcChainData memory srcData,
            EvmDstChainData memory dstData,
            bytes memory payload
        )
    {
        validateIncomingMessage(message);
        decodedMessageConfig = decodeMessageConfig(message.messageConfig);

        srcData = abi.decode(message.srcChainData, (EvmSrcChainData));
        dstData = abi.decode(message.dstChainData, (EvmDstChainData));
        payload = message.message;
    }
}
