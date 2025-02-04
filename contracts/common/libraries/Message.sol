// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "../../ConceroRouter/libraries/Types.sol";
import {SupportedChains} from "./SupportedChains.sol";

library MessageConstants {
    uint8 internal constant VERSION = 1;
    uint256 internal constant MESSAGE_BASE_FEE_USD = 1e18 / 100; // 0.01 USD
    uint256 internal constant MAX_MESSAGE_SIZE = 1e6; // 1 MB

    /* MESSAGE CONFIG OFFSETS */
    uint8 internal constant OFFSET_VERSION = 248;
    uint8 internal constant OFFSET_SRC_CHAIN = 224;
    uint8 internal constant OFFSET_DST_CHAIN = 192;
    uint8 internal constant OFFSET_MIN_SRC_CONF = 176;
    uint8 internal constant OFFSET_MIN_DST_CONF = 160;
    uint8 internal constant OFFSET_RELAYER_CONF = 152;
    uint8 internal constant OFFSET_CALLBACKABLE = 151;
    uint8 internal constant OFFSET_FEE_TOKEN = 143;

    /* MESSAGE REPORT SIZES */
    uint8 internal constant ADDRESS_LENGTH = 20;
    uint8 internal constant WORD_SIZE = 32;
    uint8 internal constant UINT32_SIZE = 4;
    uint8 internal constant UINT16_SIZE = 2;
    uint8 internal constant BYTES_ARRAY_LENGTH_SLOT = 32;
}

library Message {
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
    error InvalidDstChainData();
    error InvalidSrcChainData();
    error MessageTooLarge();
    error InvalidClientMessageConfig(ConfigError error);
    error InvalidInternalMessageConfig(ConfigError error);
    error InvalidOperatorLength();

    /* VALIDATION FUNCTIONS */
    function validateClientMessageRequest(
        uint256 config,
        uint24 chainSelector,
        bytes calldata dstChainData,
        bytes calldata message
    ) internal pure {
        validateClientMessageConfig(config, chainSelector);
        require(dstChainData.length > 0, InvalidDstChainData());
        require(message.length < MessageConstants.MAX_MESSAGE_SIZE, MessageTooLarge());
    }

    function validateInternalMessage(
        uint256 internalMessageConfig,
        bytes memory dstChainData
    ) internal pure {
        validateInternalMessageConfig(internalMessageConfig);
        //        require(message.srcChainData.length > 0, InvalidSrcChainData());
        require(dstChainData.length > 0, InvalidDstChainData());
    }

    function validateClientMessageConfig(uint256 clientConfig, uint24 chainSelector) internal pure {
        uint24 dstChainSelector = uint24(clientConfig >> MessageConstants.OFFSET_DST_CHAIN);
        uint16 minSrcConfirmations = uint16(clientConfig >> MessageConstants.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(clientConfig >> MessageConstants.OFFSET_MIN_DST_CONF);
        uint8 additionalRelayers = uint8(clientConfig >> MessageConstants.OFFSET_RELAYER_CONF);
        bool isCallbackable = ((clientConfig >> MessageConstants.OFFSET_CALLBACKABLE) & 1) != 0;
        uint8 feeToken = uint8(clientConfig >> MessageConstants.OFFSET_FEE_TOKEN);

        require(
            SupportedChains.isChainSupported(dstChainSelector),
            InvalidClientMessageConfig(ConfigError.InvalidDstChainSelector)
        );
        require(
            minSrcConfirmations > 0 &&
                minSrcConfirmations <= SupportedChains.maxConfirmations(chainSelector),
            InvalidClientMessageConfig(ConfigError.InvalidMinSrcConfirmations)
        );
        require(
            minDstConfirmations > 0 &&
                minDstConfirmations <= SupportedChains.maxConfirmations(dstChainSelector),
            InvalidClientMessageConfig(ConfigError.InvalidMinDstConfirmations)
        );
        require(
            additionalRelayers <= 255,
            InvalidClientMessageConfig(ConfigError.InvalidAdditionalRelayers)
        );
        require(feeToken <= 255, InvalidClientMessageConfig(ConfigError.InvalidFeeToken));
    }

    function validateInternalMessageConfig(uint256 config) private pure {
        uint8 version = uint8(config >> MessageConstants.OFFSET_VERSION);
        uint8 relayerConfig = uint8(config >> MessageConstants.OFFSET_RELAYER_CONF);
        uint16 minSrcConfirmations = uint16(config >> MessageConstants.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(config >> MessageConstants.OFFSET_MIN_DST_CONF);
        uint24 srcChainSelector = uint24(config >> MessageConstants.OFFSET_SRC_CHAIN);
        uint24 dstChainSelector = uint24(config >> MessageConstants.OFFSET_DST_CHAIN);

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

    /* BUILD FUNCTIONS */
    function buildInternalMessageConfig(
        uint256 clientMessageConfig,
        uint24 srcChainSelector
    ) internal pure returns (uint256) {
        validateClientMessageConfig(clientMessageConfig, srcChainSelector);

        uint256 config = clientMessageConfig;
        config |= uint256(MessageConstants.VERSION) << MessageConstants.OFFSET_VERSION;
        config |= uint256(srcChainSelector) << MessageConstants.OFFSET_SRC_CHAIN;
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

    /* DECODE FUNCTIONS (MAY NOT BE NEEDED)*/
    function decodeInternalMessageConfig(
        uint256 config
    ) private pure returns (Types.InternalMessageConfig memory) {
        return
            Types.InternalMessageConfig({
                version: uint8(config >> MessageConstants.OFFSET_VERSION),
                srcChainSelector: uint24(config >> MessageConstants.OFFSET_SRC_CHAIN),
                dstChainSelector: uint24(config >> MessageConstants.OFFSET_DST_CHAIN),
                minSrcConfirmations: uint16(config >> MessageConstants.OFFSET_MIN_SRC_CONF),
                minDstConfirmations: uint16(config >> MessageConstants.OFFSET_MIN_DST_CONF),
                relayerConfig: uint8(config >> MessageConstants.OFFSET_RELAYER_CONF),
                isCallbackable: (config & (1 << MessageConstants.OFFSET_CALLBACKABLE)) != 0
            });
    }

    /**
     * @notice Decodes a packed message report result
     * @param packedResult The packed binary data
     * @return version The version number
     * @return reportType The type of report
     * @return operator The operator address
     * @return internalMessageConfig The internal message configuration
     * @return messageId The message ID
     * @return messageHashSum The message hash sum
     * @return dstChainData The destination chain data
     * @return allowedOperators Array of allowed operator addresses
     */
    function decodeResult(
        bytes memory packedResult
    )
        public
        pure
        returns (
            uint8 version,
            uint8 reportType,
            address operator,
            uint256 internalMessageConfig,
            bytes32 messageId,
            uint256 messageHashSum,
            bytes memory dstChainData,
            address[] memory allowedOperators
        )
    {
        // Cache constants in local variables for assembly access
        uint256 bytesArrayLengthSlot = uint256(MessageConstants.BYTES_ARRAY_LENGTH_SLOT);
        uint256 addressLength = uint256(MessageConstants.ADDRESS_LENGTH);
        uint256 wordSize = uint256(MessageConstants.WORD_SIZE);
        uint256 uint32Size = uint256(MessageConstants.UINT32_SIZE);
        uint256 uint16Size = uint256(MessageConstants.UINT16_SIZE);

        uint256 offset = 0;

        // Decode operator address
        uint8 operatorLength = uint8(packedResult[offset++]);
        require(operatorLength == MessageConstants.ADDRESS_LENGTH, InvalidOperatorLength());

        bytes32 operatorBytes;
        assembly {
            operatorBytes := mload(add(add(packedResult, bytesArrayLengthSlot), offset))
        }
        offset += addressLength;

        // Decode 32-byte values using wordSize
        assembly {
            internalMessageConfig := mload(add(add(packedResult, bytesArrayLengthSlot), offset))
        }
        offset += wordSize;

        // Decode dstChainData length
        uint32 dstChainDataLength;
        assembly {
            let lengthPtr := add(add(packedResult, bytesArrayLengthSlot), offset)
            dstChainDataLength := and(mload(lengthPtr), 0xffffffff)
        }
        offset += uint32Size;

        // Decode operators count
        uint16 operatorsCount;
        assembly {
            let countPtr := add(add(packedResult, bytesArrayLengthSlot), offset)
            operatorsCount := and(mload(countPtr), 0xffff)
        }
        offset += uint16Size;

        // Decode allowed operators
        allowedOperators = new address[](operatorsCount);
        for (uint i = 0; i < operatorsCount; i++) {
            bytes32 addrBytes;
            assembly {
                addrBytes := mload(add(add(packedResult, bytesArrayLengthSlot), offset))
            }
            allowedOperators[i] = address(uint160(uint256(addrBytes)));
            offset += addressLength;
        }

        return (
            version,
            reportType,
            operator,
            internalMessageConfig,
            bytes32(messageId),
            messageHashSum,
            dstChainData,
            allowedOperators
        );
    }

    /**
     * @notice Decodes the complete message including internal config
     * @param packedResult The packed binary data
     * @return decodedMessageConfig The decoded internal message configuration
     * @return messageId The id of the message
     * @return messageHashSum The message hash sum
     * @return dstChainData The destination chain data
     */
    function _decodeMessage(
        bytes memory packedResult
    )
        internal
        pure
        returns (
            Types.InternalMessageConfig memory decodedMessageConfig,
            bytes32 messageId,
            bytes32 messageHashSum,
            bytes memory dstChainData
        )
    {
        (
            ,
            ,
            ,
            uint256 internalMessageConfig,
            bytes32 messageId,
            uint256 hashSum,
            bytes memory dstChainData,

        ) = decodeResult(packedResult);

        decodedMessageConfig = decodeInternalMessageConfig(internalMessageConfig);
        messageHashSum = bytes32(hashSum);

        //        dstData = Types.EvmDstChainData({receiver: address(0), gasLimit: 0});
    }
}
