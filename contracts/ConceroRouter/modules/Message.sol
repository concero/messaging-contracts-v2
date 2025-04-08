// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Decoder as DecoderLib} from "../../common/libraries/Decoder.sol";
import {Utils as CommonUtils} from "../../common/libraries/Utils.sol";

import {BitMasks, CommonConstants, MessageConfigBitOffsets as offsets} from "../../common/CommonConstants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";

import {IConceroClient} from "../../interfaces/IConceroClient.sol";
import {IConceroRouter, ConceroMessageDelivered, ConceroMessageReceived, ConceroMessageSent} from "../../interfaces/IConceroRouter.sol";

import {ClfSigner} from "./ClfSigner.sol";
import {Base} from "./Base.sol";

library Errors {
    error UnsupportedFeeTokenType();
    error MessageAlreadyProcessed(bytes32 messageId);
    error MessageDeliveryFailed(bytes32 messageId);
    error InvalidReceiver();
    error InvalidMessageHashSum();
    error UnauthorizedOperator();
    error InvalidDstChainSelector();
    error InvalidClientMessageConfig();
    error InvalidDstChainData();
    error InvalidSrcChainData();
    error MessageTooLarge();
}

abstract contract Message is ClfSigner, IConceroRouter {
    using SafeERC20 for IERC20;
    using s for s.Router;
    using s for s.PriceFeed;
    using s for s.Operator;

    constructor(
        address conceroVerifier,
        uint64 conceroVerifierSubId,
        address[4] memory clfSigners
    ) ClfSigner(conceroVerifier, conceroVerifierSubId, clfSigners) {}

    function validateClientMessageRequest(
        bytes32 config,
        uint24 chainSelector,
        bytes calldata dstChainData,
        bytes calldata message
    ) internal view {
        validateClientMessageConfig(config, chainSelector);
        require(dstChainData.length > 0, Errors.InvalidDstChainData());
        require(message.length < CommonConstants.MESSAGE_MAX_SIZE, Errors.MessageTooLarge());
    }

    function validateClientMessageConfig(bytes32 clientConfig, uint24 chainSelector) internal view {
        uint256 configValue = uint256(clientConfig);

        uint24 dstChainSelector = uint24(configValue >> offsets.OFFSET_DST_CHAIN);
        uint16 minSrcConfirmations = uint16(configValue >> offsets.OFFSET_MIN_SRC_CONF);
        uint16 minDstConfirmations = uint16(configValue >> offsets.OFFSET_MIN_DST_CONF);
        // uint8 additionalRelayers = uint8(configValue >> offsets.OFFSET_RELAYER_CONF);
        // bool isCallbackable = (configValue >> offsets.OFFSET_CALLBACKABLE & 1) != 0;
        CommonTypes.FeeToken feeToken = CommonTypes.FeeToken(
            uint8(configValue >> offsets.OFFSET_FEE_TOKEN)
        );

        require(feeToken == CommonTypes.FeeToken.native, Errors.InvalidClientMessageConfig());

        //@notice: this is being moved to conceroVerifier
        // require(
        //     SupportedChains.isChainSupported(dstChainSelector),
        //     InvalidClientMessageConfig(MessageConfigErrorType.InvalidDstChainSelector)
        // );
        // require(
        //     minSrcConfirmations > 0 &&
        //         minSrcConfirmations <= SupportedChains.maxConfirmations(chainSelector),
        //     InvalidClientMessageConfig(MessageConfigErrorType.InvalidMinSrcConfirmations)
        // );
        // require(
        //     minDstConfirmations > 0 &&
        //         minDstConfirmations <= SupportedChains.maxConfirmations(dstChainSelector),
        //     InvalidClientMessageConfig(MessageConfigErrorType.InvalidMinDstConfirmations)
        // );
    }

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

    function conceroSend(
        bytes32 config,
        bytes calldata dstChainData,
        bytes calldata message
    ) external payable returns (bytes32) {
        _collectMessageFee(config, dstChainData);

        (bytes32 messageId, bytes32 internalMessageConfig) = buildInternalMessage(
            config,
            dstChainData,
            message,
            i_chainSelector,
            // @dev TODO: we can use ++s.router().nonce
            s.router().nonce
        );

        s.router().nonce += 1;

        emit ConceroMessageSent(
            internalMessageConfig,
            messageId,
            dstChainData,
            message,
            abi.encode(msg.sender)
        );
        return messageId;
    }

    /**
     * @notice Submits a message report, verifies the signatures, and processes the report data.
     * @param reportSubmission the serialized report data.
     * @param message the message data.
     */
    function submitMessageReport(
        Types.ClfDonReportSubmission calldata reportSubmission,
        bytes calldata message
    ) external {
        Types.ClfReport memory clfReport = DecoderLib._decodeCLFReport(reportSubmission.report);
        _verifyClfReportSignatures(reportSubmission);

        Types.ClfReportOnchainMetadata memory onchainMetadata = abi.decode(
            clfReport.onchainMetadata[0],
            (Types.ClfReportOnchainMetadata)
        );

        _verifyClfReportOnChainMetadata(onchainMetadata);

        CommonTypes.MessageReportResult memory decodedMessageReportResult = DecoderLib
            ._decodeCLFMessageReportResponse(clfReport.results[0]);

        require(
            decodedMessageReportResult.messageHashSum == keccak256(message),
            Errors.InvalidMessageHashSum()
        );

        require(
            uint24(
                uint256(decodedMessageReportResult.internalMessageConfig) >>
                    offsets.OFFSET_DST_CHAIN
            ) == i_chainSelector,
            Errors.InvalidDstChainSelector()
        );

        require(
            !s.router().isMessageProcessed[decodedMessageReportResult.messageId],
            Errors.MessageAlreadyProcessed(decodedMessageReportResult.messageId)
        );

        bool isAllowedOperator = false;

        for (uint256 i = 0; i < decodedMessageReportResult.allowedOperators.length; i++) {
            address allowedOperator = abi.decode(
                decodedMessageReportResult.allowedOperators[i],
                (address)
            );

            if (allowedOperator == msg.sender) {
                isAllowedOperator = true;
                break;
            }
        }

        require(isAllowedOperator, Errors.UnauthorizedOperator());

        emit ConceroMessageReceived(decodedMessageReportResult.messageId);

        uint24 srcChainSelector = uint24(
            uint256(decodedMessageReportResult.internalMessageConfig) >> offsets.OFFSET_SRC_CHAIN
        );

        deliverMessage(
            decodedMessageReportResult.messageId,
            decodedMessageReportResult.dstChainData,
            srcChainSelector,
            decodedMessageReportResult.sender,
            message
        );
    }

    /**
     * @notice Delivers the message to the receiver contract if valid.
     * @param messageId The unique identifier of the message.
     * @param dstData The destination chain data of the message.
     * @param message The message data.
     */
    function deliverMessage(
        bytes32 messageId,
        bytes memory dstData,
        uint24 srcChainSelector,
        bytes memory sender,
        bytes memory message
    ) internal {
        Types.EvmDstChainData memory dstData = abi.decode(dstData, (Types.EvmDstChainData));

        s.router().isMessageProcessed[messageId] = true;

        require(dstData.receiver != address(0), Errors.InvalidReceiver());
        require(CommonUtils.isContract(dstData.receiver), Errors.InvalidReceiver());

        bytes memory callData = abi.encodeWithSelector(
            IConceroClient.conceroReceive.selector,
            messageId,
            srcChainSelector,
            sender,
            message
        );

        (bool success, ) = CommonUtils.safeCall(
            dstData.receiver,
            dstData.gasLimit,
            0,
            256,
            callData
        );

        if (!success) {
            revert Errors.MessageDeliveryFailed(messageId);
        }

        s.operator().feesEarnedNative[msg.sender] += CommonUtils.convertUsdBpsToNative(
            CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            s.priceFeed().nativeUsdRate
        );

        emit ConceroMessageDelivered(messageId);
    }

    /* INTERNAL FUNCTIONS */
    function _collectMessageFee(bytes32 clientMessageConfig, bytes memory dstChainData) internal {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(uint256(clientMessageConfig >> offsets.OFFSET_FEE_TOKEN) & BitMasks.MASK_8)
        );

        uint256 messageFee = _calculateMessageFee(clientMessageConfig, dstChainData, feeToken);

        if (feeToken == Types.FeeToken.native) {
            require(msg.value >= messageFee, CommonErrors.InsufficientFee(msg.value, messageFee));
            payable(address(this)).transfer(messageFee);
        }
        //        else if (feeToken == Types.FeeToken.usdc) {
        //            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), messageFee);
        //        }
        else {
            revert Errors.UnsupportedFeeTokenType();
        }
    }

    //todo: adhere to SOLID. it shouldnt extract values from client config, do it on the level above
    function _calculateMessageFee(
        bytes32 clientMessageConfig,
        bytes memory dstChainData,
        Types.FeeToken feeToken
    ) internal view returns (uint256) {
        uint256 nativeUsdRate = s.priceFeed().nativeUsdRate;
        Types.EvmDstChainData memory evmDstChainData = abi.decode(
            dstChainData,
            (Types.EvmDstChainData)
        );

        uint24 dstChainSelector = uint24(
            uint256(clientMessageConfig >> offsets.OFFSET_DST_CHAIN) & BitMasks.MASK_24
        );

        uint256 baseFeeNative = CommonUtils.convertUsdBpsToNative(
            CommonConstants.CONCERO_MESSAGE_BASE_FEE_BPS_USD,
            nativeUsdRate
        );

        uint256 gasPrice = s.priceFeed().lastGasPrices[dstChainSelector];
        uint256 gasFeeNative = gasPrice * evmDstChainData.gasLimit;

        uint256 nativeNativeRate = s.getNativeNativeRate(dstChainSelector);
        uint256 adjustedGasFeeNative = (gasFeeNative * nativeNativeRate) / 1e18;

        uint256 totalFeeNative = baseFeeNative + adjustedGasFeeNative;

        if (feeToken == Types.FeeToken.native) {
            return totalFeeNative;
        }

        return (totalFeeNative * nativeUsdRate) / 1e18;
    }

    function getMessageFee(
        bytes32 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(uint256(clientMessageConfig >> offsets.OFFSET_FEE_TOKEN) & BitMasks.MASK_8)
        );
        require(feeToken == Types.FeeToken.native, Errors.UnsupportedFeeTokenType());
        return _calculateMessageFee(clientMessageConfig, dstChainData, feeToken);
    }
}
