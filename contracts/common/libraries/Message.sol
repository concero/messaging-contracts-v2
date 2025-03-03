// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "../../ConceroRouter/libraries/Types.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";
import {CommonConstants, MessageConfigBitOffsets as offsets, ReportByteSizes} from "../../common/CommonConstants.sol";
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
        bytes32 config,
        uint24 chainSelector,
        bytes calldata dstChainData,
        bytes calldata message
    ) internal pure {
        validateClientMessageConfig(config, chainSelector);
        require(dstChainData.length > 0, InvalidDstChainData());
        require(message.length < CommonConstants.MESSAGE_MAX_SIZE, MessageTooLarge());
    }

    function validateInternalMessage(
        bytes32 internalMessageConfig,
        bytes memory srcChainData,
        bytes memory dstChainData
    ) internal pure {
        validateInternalMessageConfig(internalMessageConfig);
        require(srcChainData.length > 0, InvalidSrcChainData());
        require(dstChainData.length > 0, InvalidDstChainData());
    }

    function validateClientMessageConfig(bytes32 clientConfig, uint24 chainSelector) internal pure {
        uint256 configValue = uint256(clientConfig);

        uint24 dstChainSelector = uint24(configValue >> offsets.OFFSET_DST_CHAIN);
        uint16 minSrcConfirmations = uint16(configValue >> offsets.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(configValue >> offsets.OFFSET_MIN_DST_CONF);
        // uint8 additionalRelayers = uint8(configValue >> offsets.OFFSET_RELAYER_CONF);
        // bool isCallbackable = (configValue >> offsets.OFFSET_CALLBACKABLE & 1) != 0;
        CommonTypes.FeeToken feeToken = CommonTypes.FeeToken(
            uint8(configValue >> offsets.OFFSET_FEE_TOKEN)
        );

        require(
            feeToken == CommonTypes.FeeToken.native,
            InvalidClientMessageConfig(MessageConfigErrorType.InvalidFeeToken)
        );
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
    }

    function validateInternalMessageConfig(bytes32 config) private pure {
        uint256 configValue = uint256(config);

        uint8 version = uint8(configValue >> offsets.OFFSET_VERSION);
        uint8 relayerConfig = uint8(configValue >> offsets.OFFSET_RELAYER_CONF);
        uint16 minSrcConfirmations = uint16(configValue >> offsets.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(configValue >> offsets.OFFSET_MIN_DST_CONF);
        uint24 srcChainSelector = uint24(configValue >> offsets.OFFSET_SRC_CHAIN);
        uint24 dstChainSelector = uint24(configValue >> offsets.OFFSET_DST_CHAIN);

        require(
            version >= 1 && version < 2,
            InvalidInternalMessageConfig(MessageConfigErrorType.InvalidConfigVersion)
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
        bytes32 clientMessageConfig,
        uint24 srcChainSelector
    ) internal pure returns (bytes32) {
        return
            bytes32(
                uint256(clientMessageConfig) |
                    (uint256(CommonConstants.MESSAGE_VERSION) << offsets.OFFSET_VERSION) |
                    (uint256(srcChainSelector) << offsets.OFFSET_SRC_CHAIN)
            );
    }

    function buildInternalMessage(
        bytes32 clientMessageConfig,
        bytes calldata dstChainData,
        bytes calldata message,
        uint24 chainSelector,
        uint256 nonce
    ) internal view returns (bytes32 messageId, bytes32 internalMessageConfig) {
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
        bytes32 internalMessageConfig
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(nonce, blockNumber, sender, chainSelector, internalMessageConfig)
            );
    }
}
