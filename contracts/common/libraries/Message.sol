// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "../../ConceroRouter/libraries/Types.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";
import {CommonConstants, MessageConfigBitOffsets, ReportByteSizes} from "../../common/CommonConstants.sol";
import {SupportedChains} from "./SupportedChains.sol";

import {console} from "forge-std/src/console.sol";

library Message {
    enum MessageConfigErrorType {
        InvalidMinSrcConfirmations, // 0
        InvalidMinDstConfirmations, // 1
        InvalidAdditionalRelayers, // 2
        InvalidFeeToken, // 3
        InvalidConfigVersion, // 4
        InvalidRelayerConfig, // 5
        InvalidSrcChainSelector, // 6
        InvalidDstChainSelector, // 7
        InvalidOperatorLength // 8
    }

    error MessageTooLarge();
    error InvalidClientMessageConfig(MessageConfigErrorType error);
    error InvalidDstChainData();
    error InvalidSrcChainData();
    error InvalidInternalMessageConfig(MessageConfigErrorType error);

    /* VALIDATION FUNCTIONS */
    function validateClientMessageRequest(
        uint256 config,
        uint24 chainSelector,
        bytes calldata dstChainData,
        bytes calldata message
    ) internal pure {
        validateClientMessageConfig(config, chainSelector);
        require(dstChainData.length > 0, InvalidDstChainData());
        require(message.length < CommonConstants.MESSAGE_MAX_SIZE, MessageTooLarge());
    }

    function validateInternalMessage(
        uint256 internalMessageConfig,
        bytes memory srcChainData,
        bytes memory dstChainData
    ) internal pure {
        validateInternalMessageConfig(internalMessageConfig);
        require(srcChainData.length > 0, InvalidSrcChainData());
        require(dstChainData.length > 0, InvalidDstChainData());
    }

    function validateClientMessageConfig(uint256 clientConfig, uint24 chainSelector) internal pure {
        uint24 dstChainSelector = uint24(clientConfig >> MessageConfigBitOffsets.OFFSET_DST_CHAIN);
        uint16 minSrcConfirmations = uint16(
            clientConfig >> MessageConfigBitOffsets.OFFSET_MIN_SRC_CONF
        );
        uint16 minDstConfirmations = uint16(
            clientConfig >> MessageConfigBitOffsets.OFFSET_MIN_DST_CONF
        );
        uint8 additionalRelayers = uint8(
            clientConfig >> MessageConfigBitOffsets.OFFSET_RELAYER_CONF
        );
        bool isCallbackable = ((clientConfig >> MessageConfigBitOffsets.OFFSET_CALLBACKABLE) & 1) !=
            0;
        uint8 feeToken = uint8(clientConfig >> MessageConfigBitOffsets.OFFSET_FEE_TOKEN);

        require(
            SupportedChains.isChainSupported(dstChainSelector),
            InvalidClientMessageConfig(MessageConfigErrorType.InvalidDstChainSelector)
        );
        require(
            minSrcConfirmations > 0 &&
                minSrcConfirmations <= SupportedChains.maxConfirmations(chainSelector),
            InvalidClientMessageConfig(MessageConfigErrorType.InvalidMinSrcConfirmations)
        );
        require(
            minDstConfirmations > 0 &&
                minDstConfirmations <= SupportedChains.maxConfirmations(dstChainSelector),
            InvalidClientMessageConfig(MessageConfigErrorType.InvalidMinDstConfirmations)
        );
        require(
            additionalRelayers <= 255,
            InvalidClientMessageConfig(MessageConfigErrorType.InvalidAdditionalRelayers)
        );
        require(
            feeToken <= 255,
            InvalidClientMessageConfig(MessageConfigErrorType.InvalidFeeToken)
        );
    }

    function validateInternalMessageConfig(uint256 config) private pure {
        uint8 version = uint8(config >> MessageConfigBitOffsets.OFFSET_VERSION);
        uint8 relayerConfig = uint8(config >> MessageConfigBitOffsets.OFFSET_RELAYER_CONF);
        uint16 minSrcConfirmations = uint16(config >> MessageConfigBitOffsets.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(config >> MessageConfigBitOffsets.OFFSET_MIN_DST_CONF);
        uint24 srcChainSelector = uint24(config >> MessageConfigBitOffsets.OFFSET_SRC_CHAIN);
        uint24 dstChainSelector = uint24(config >> MessageConfigBitOffsets.OFFSET_DST_CHAIN);

        require(
            version > 0,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidConfigVersion)
        );
        require(
            relayerConfig <= 255,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidRelayerConfig)
        );
        require(
            minSrcConfirmations > 0,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidMinSrcConfirmations)
        );
        require(
            minDstConfirmations > 0,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidMinDstConfirmations)
        );
        require(
            SupportedChains.isChainSupported(srcChainSelector),
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidSrcChainSelector)
        );
        require(
            SupportedChains.isChainSupported(dstChainSelector),
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidDstChainSelector)
        );
    }

    /* BUILD FUNCTIONS */
    function buildInternalMessageConfig(
        uint256 clientMessageConfig,
        uint24 srcChainSelector
    ) internal pure returns (uint256) {
        validateClientMessageConfig(clientMessageConfig, srcChainSelector);

        uint256 config = clientMessageConfig;
        config |=
            uint256(CommonConstants.MESSAGE_VERSION) <<
            MessageConfigBitOffsets.OFFSET_VERSION;
        config |= uint256(srcChainSelector) << MessageConfigBitOffsets.OFFSET_SRC_CHAIN;
        return config;
    }

    function buildInternalMessage(
        uint256 clientMessageConfig,
        bytes calldata dstChainData,
        bytes calldata message,
        uint24 chainSelector,
        uint256 nonce
    ) internal view returns (bytes32 messageId, uint256 internalMessageConfig) {
        validateClientMessageRequest(clientMessageConfig, chainSelector, dstChainData, message);

        Types.EvmSrcChainData memory srcChainData = Types.EvmSrcChainData({
            sender: msg.sender,
            blockNumber: block.number
        });

        internalMessageConfig = buildInternalMessageConfig(clientMessageConfig, chainSelector);

        messageId = buildMessageId(
            nonce,
            srcChainData.blockNumber,
            srcChainData.sender,
            chainSelector,
            internalMessageConfig
        );

        return (messageId, internalMessageConfig);
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
}
