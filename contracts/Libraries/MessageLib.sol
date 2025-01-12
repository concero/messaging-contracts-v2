// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {EvmSrcChainData, MessageEventParams, InternalMessageConfig, EvmDstChainData} from "../Common/MessageTypes.sol";
import {SupportedChains} from "./SupportedChains.sol";

library MessageConfigConstants {
    uint8 internal constant VERSION = 1;
    uint256 internal constant MESSAGE_BASE_FEE_USD = 1e18 / 100; // 0.01 USD
    uint256 internal constant MAX_MESSAGE_SIZE = 1e6; // 1 MB

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
    error MessageTooLarge();
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
        uint256 clientMessageConfig,
        uint24 srcChainSelector
    ) internal pure returns (uint256) {
        validateClientMessageConfig(clientMessageConfig);

        uint256 config = clientMessageConfig;
        config |= uint256(MessageConfigConstants.VERSION) << MessageConfigConstants.OFFSET_VERSION;
        config |= uint256(srcChainSelector) << MessageConfigConstants.OFFSET_SRC_CHAIN;
        return config;
    }

    function buildInternalMessage(
        uint256 config,
        bytes calldata dstChainData,
        bytes calldata message,
        uint24 chainSelector,
        uint256 nonce
    ) internal view returns (bytes32, MessageEventParams memory) {
        validateClientMessageRequest(config, dstChainData, message);

        EvmSrcChainData memory srcChainData = EvmSrcChainData({
            sender: msg.sender,
            blockNumber: block.number
        });

        uint256 internalMessageConfig = buildInternalMessageConfig(config, chainSelector);

        bytes32 messageId = buildMessageId(
            nonce,
            srcChainData.blockNumber,
            srcChainData.sender,
            chainSelector,
            internalMessageConfig
        );

        return (
            messageId,
            MessageEventParams({
                internalMessageConfig: internalMessageConfig,
                dstChainData: dstChainData
            })
        );
    }
    function buildMessageId(
        uint256 nonce,
        uint256 blockNumber,
        address sender,
        uint64 chainSelector,
        uint256 internalMessageConfig
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(nonce, blockNumber, sender, chainSelector, internalMessageConfig)
            );
    }

    /* VALIDATION FUNCTIONS */
    function validateClientMessageRequest(
        uint256 config,
        bytes calldata dstChainData,
        bytes calldata message
    ) internal pure {
        validateClientMessageConfig(config);
        require(dstChainData.length > 0, InvalidDstChainData());
        require(message.length < MessageConfigConstants.MAX_MESSAGE_SIZE, MessageTooLarge());
    }

    function validateInternalMessage_(MessageEventParams memory message) internal pure {
        validateInternalMessageConfig(message.internalMessageConfig);
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

    /* DECODE FUNCTIONS (MAY NOT BE NEEDED)*/
    //    function decodeInternalMessageConfig(
    //        uint256 config
    //    ) private pure returns (InternalMessageConfig memory) {
    //        return
    //            InternalMessageConfig({
    //                version: uint8(config >> MessageConfigConstants.OFFSET_VERSION),
    //                srcChainSelector: uint24(config >> MessageConfigConstants.OFFSET_SRC_CHAIN),
    //                dstChainSelector: uint24(config >> MessageConfigConstants.OFFSET_DST_CHAIN),
    //                minSrcConfirmations: uint16(config >> MessageConfigConstants.OFFSET_MIN_SRC_CONF),
    //                minDstConfirmations: uint16(config >> MessageConfigConstants.OFFSET_MIN_DST_CONF),
    //                relayerConfig: uint8(config >> MessageConfigConstants.OFFSET_RELAYER_CONF),
    //                isCallbackable: (config & (1 << MessageConfigConstants.OFFSET_CALLBACKABLE)) != 0
    //            });
    //    }
    //
    //    function decodeInternalMessage(
    //        InternalMessageEvent memory message
    //    )
    //        internal
    //        pure
    //        returns (
    //            InternalMessageConfig memory decodedMessageConfig,
    //            bytes32 messageHashSum,
    //            EvmSrcChainData memory srcData,
    //            EvmDstChainData memory dstData
    //        )
    //    {
    //        validateInternalMessage_(message);
    //
    //        decodedMessageConfig = decodeInternalMessageConfig(message.internalMessageConfig);
    //        messageHashSum = message.messageHashSum;
    //        srcData = abi.decode(message.srcChainData, (EvmSrcChainData));
    //        dstData = abi.decode(message.dstChainData, (EvmDstChainData));
    //    }
}
