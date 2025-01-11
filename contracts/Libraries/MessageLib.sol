// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ClientMessageRequest, EvmSrcChainData, InternalMessage, InternalMessageConfig, EvmDstChainData} from "../Common/MessageTypes.sol";
import {SupportedChains} from "./SupportedChains.sol";

library MessageConfigConstants {
    uint8 internal constant VERSION = 1;
    uint256 internal constant MESSAGE_BASE_FEE_USD = 1e18 / 100; // 0.01 USD

    /* OFFSETS */
    uint8 internal constant OFFSET_VERSION = 248;
    uint8 internal constant OFFSET_SRC_CHAIN = 224;
    uint8 internal constant OFFSET_DST_CHAIN = 192;
    uint8 internal constant OFFSET_MIN_SRC_CONF = 176;
    uint8 internal constant OFFSET_MIN_DST_CONF = 160;
    uint8 internal constant OFFSET_RELAYER_CONF = 152;
    uint8 internal constant OFFSET_CALLBACKABLE = 151;
    uint8 internal constant OFFSET_FEE_TOKEN = 143;
}

library MessageLib {
    error InvalidDstChainData();
    error InvalidSrcChainData();
    error InvalidClientMessageConfig(ConfigError error);
    error InvalidInternalMessageConfig(ConfigError error);

    enum ConfigError {
        InvalidMinSrcConfirmations,
        InvalidMinDstConfirmations,
        InvalidAdditionalRelayers,
        InvalidFeeToken,
        InvalidConfigVersion,
        InvalidRelayerConfig,
        InvalidSrcChainSelector,
        InvalidDstChainSelector
    }

    /* BUILD FUNCTIONS */
    function buildInternalMessageConfig(
        uint256 config,
        uint24 srcChainSelector
    ) internal pure returns (uint256) {
        validateClientMessageConfig(config);
        config |= uint256(MessageConfigConstants.VERSION) << MessageConfigConstants.OFFSET_VERSION;
        config |= uint256(srcChainSelector) << MessageConfigConstants.OFFSET_SRC_CHAIN;
        return config;
    }

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
                srcChainData: srcChainData,
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

    /* VALIDATION FUNCTIONS */
    function validateMessageRequest(ClientMessageRequest memory req) internal pure {
        validateInternalMessageConfig(req.messageConfig);
        require(req.dstChainData.length > 0, InvalidDstChainData());
    }

    function validateInternalMessage_(InternalMessage memory message) internal pure {
        validateInternalMessageConfig(message.messageConfig);
        //        require(message.srcChainData.length > 0, InvalidSrcChainData());
        require(message.dstChainData.length > 0, InvalidDstChainData());
    }

    function validateClientMessageConfig(uint256 clientConfig) internal pure {
        uint24 dstChainSelector = uint24(clientConfig >> MessageConfigConstants.OFFSET_DST_CHAIN);
        uint16 minSrcConfirmations = uint16(
            clientConfig >> MessageConfigConstants.OFFSET_MIN_SRC_CONF
        );
        uint16 minDstConfirmations = uint16(
            clientConfig >> MessageConfigConstants.OFFSET_MIN_DST_CONF
        );
        uint8 additionalRelayers = uint8(
            clientConfig >> MessageConfigConstants.OFFSET_RELAYER_CONF
        );
        bool isCallbackable = ((clientConfig >> MessageConfigConstants.OFFSET_CALLBACKABLE) & 1) !=
            0;
        uint8 feeToken = uint8(clientConfig >> MessageConfigConstants.OFFSET_FEE_TOKEN);

        require(
            dstChainSelector > 0,
            InvalidClientMessageConfig(ConfigError.InvalidDstChainSelector)
        );
        require(
            minSrcConfirmations > 0,
            InvalidClientMessageConfig(ConfigError.InvalidMinSrcConfirmations)
        );
        require(
            minDstConfirmations > 0,
            InvalidClientMessageConfig(ConfigError.InvalidMinDstConfirmations)
        );
        require(
            additionalRelayers <= 255,
            InvalidClientMessageConfig(ConfigError.InvalidAdditionalRelayers)
        );
        require(feeToken <= 255, InvalidClientMessageConfig(ConfigError.InvalidFeeToken));
    }

    function validateInternalMessageConfig(uint256 config) private pure {
        uint8 version = uint8(config >> MessageConfigConstants.OFFSET_VERSION);
        uint8 relayerConfig = uint8(config >> MessageConfigConstants.OFFSET_RELAYER_CONF);
        uint16 minSrcConfirmations = uint16(config >> MessageConfigConstants.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(config >> MessageConfigConstants.OFFSET_MIN_DST_CONF);
        uint24 srcChainSelector = uint24(config >> MessageConfigConstants.OFFSET_SRC_CHAIN);
        uint24 dstChainSelector = uint24(config >> MessageConfigConstants.OFFSET_DST_CHAIN);

        require(version > 0, InvalidInternalMessageConfig(ConfigError.InvalidConfigVersion));
        require(
            relayerConfig <= 255,
            InvalidInternalMessageConfig(ConfigError.InvalidRelayerConfig)
        );
        require(
            minSrcConfirmations > 0,
            InvalidInternalMessageConfig(ConfigError.InvalidMinSrcConfirmations)
        );
        require(
            minDstConfirmations > 0,
            InvalidInternalMessageConfig(ConfigError.InvalidMinDstConfirmations)
        );
        require(
            SupportedChains.isChainSupported(srcChainSelector),
            InvalidInternalMessageConfig(ConfigError.InvalidSrcChainSelector)
        );
        require(
            SupportedChains.isChainSupported(dstChainSelector),
            InvalidInternalMessageConfig(ConfigError.InvalidDstChainSelector)
        );
    }

    /* DECODE FUNCTIONS */
    function decodeInternalMessageConfig(
        uint256 config
    ) private pure returns (InternalMessageConfig memory) {
        return
            InternalMessageConfig({
                version: uint8(config >> MessageConfigConstants.OFFSET_VERSION),
                srcChainSelector: uint24(config >> MessageConfigConstants.OFFSET_SRC_CHAIN),
                dstChainSelector: uint24(config >> MessageConfigConstants.OFFSET_DST_CHAIN),
                minSrcConfirmations: uint16(config >> MessageConfigConstants.OFFSET_MIN_SRC_CONF),
                minDstConfirmations: uint16(config >> MessageConfigConstants.OFFSET_MIN_DST_CONF),
                relayerConfig: uint8(config >> MessageConfigConstants.OFFSET_RELAYER_CONF),
                isCallbackable: (config & (1 << MessageConfigConstants.OFFSET_CALLBACKABLE)) != 0
            });
    }

    function decodeInternalMessage(
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
        validateInternalMessage_(message);
        decodedMessageConfig = decodeInternalMessageConfig(message.messageConfig);

        srcData = abi.decode(message.srcChainData, (EvmSrcChainData));
        dstData = abi.decode(message.dstChainData, (EvmDstChainData));
        payload = message.message;
    }
}
