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

import {ConceroTypes} from "../../ConceroClient/ConceroTypes.sol";
import {BitMasks, CommonConstants, MessageConfigBitOffsets as offsets} from "../../common/CommonConstants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";

import {IConceroClient} from "../../interfaces/IConceroClient.sol";
import {IConceroRouter, ConceroMessageDelivered, ConceroMessageReceived, ConceroMessageSent, MessageReorgDetected} from "../../interfaces/IConceroRouter.sol";

import {ClfSigner} from "./ClfSigner.sol";
import {Base} from "./Base.sol";

library Errors {
    error UnsupportedFeeTokenType();
    error MessageAlreadyProcessed(bytes32 messageId);
    error MessageDeliveryFailed(bytes32 messageId);
    error InvalidReceiver();
    error InvalidGasLimit();
    error InvalidMessageHashSum();
    error UnauthorizedOperator();
    error InvalidDstChainSelector();
    error InvalidClientMessageConfig();
    error InvalidSrcChainData();
    error MessageTooLarge();
    error FinalityNotYetSupported();
}

abstract contract Message is ClfSigner, IConceroRouter {
    using SafeERC20 for IERC20;
    using s for s.Router;
    using s for s.PriceFeed;
    using s for s.Operator;

    uint8 private constant MESSAGE_VERSION = 1;

    constructor(
        address conceroVerifier,
        uint64 conceroVerifierSubId,
        address[4] memory clfSigners
    ) ClfSigner(conceroVerifier, conceroVerifierSubId, clfSigners) {}

    /* @inheritdoc IConceroRouter */
    function conceroSend(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData,
        bytes calldata message
    ) external payable returns (bytes32) {
        _validateMessageParams(
            dstChainSelector,
            shouldFinaliseSrc,
            feeToken,
            dstChainData,
            message
        );
        _collectMessageFee(dstChainSelector, feeToken, dstChainData);

        bytes32 messageId = _buildMessageId(dstChainSelector);

        emit ConceroMessageSent(
            messageId,
            MESSAGE_VERSION,
            shouldFinaliseSrc,
            dstChainSelector,
            abi.encode(dstChainData),
            msg.sender,
            message
        );

        return messageId;
    }

    /**
     * @notice Submits a message report, verifies the signatures, and processes the report data.
     * @param reportSubmission the serialized report data.
     * @param messageBodies the array of message bodies.
     * @param indexes the array of indexes.
     */
    function submitMessageReport(
        Types.ClfDonReportSubmission calldata reportSubmission,
        bytes[] calldata messageBodies,
        uint256[] calldata indexes
    ) external {
        require(messageBodies.length == indexes.length, CommonErrors.LengthMismatch());

        _verifyClfReportSignatures(reportSubmission);

        Types.ClfReport memory clfReport = DecoderLib._decodeCLFReport(reportSubmission.report);

        Types.ClfReportOnchainMetadata memory onchainMetadata = abi.decode(
            clfReport.onchainMetadata[0],
            (Types.ClfReportOnchainMetadata)
        );

        _verifyClfReportOnChainMetadata(onchainMetadata);

        for (uint256 i; i < indexes.length; ++i) {
            (CommonTypes.ResultConfig memory resultConfig, bytes memory payload) = DecoderLib
                ._decodeVerifierResult(clfReport.results[indexes[i]]);

            if (resultConfig.payloadVersion == 1) {
                _handleMessagePayloadV1(payload, messageBodies[i]);
            }
        }
    }

    /* INTERNAL FUNCTIONS */

    function _handleMessagePayloadV1(
        bytes memory _messagePayload,
        bytes memory messageBody
    ) internal {
        CommonTypes.MessagePayloadV1 memory messagePayload = abi.decode(
            _messagePayload,
            (CommonTypes.MessagePayloadV1)
        );

        _verifyIsSenderOperator(messagePayload.allowedOperators);

        require(
            messagePayload.dstChainSelector == i_chainSelector,
            Errors.InvalidDstChainSelector()
        );

        require(
            messagePayload.messageHashSum == keccak256(messageBody),
            Errors.InvalidMessageHashSum()
        );

        require(
            !s.router().isMessageProcessed[messagePayload.messageId],
            Errors.MessageAlreadyProcessed(messagePayload.messageId)
        );

        // Check for reorg detection
        bytes32 lastTxHash = s.router().lastTxHash[messagePayload.srcChainSelector];
        if (lastTxHash == messagePayload.txHash) {
            emit MessageReorgDetected(messagePayload.txHash, messagePayload.srcChainSelector);
            return; // Don't process the message
        }

        s.router().lastTxHash[messagePayload.srcChainSelector] = messagePayload.txHash;

        emit ConceroMessageReceived(messagePayload.messageId);

        _deliverMessage(
            messagePayload.messageId,
            messagePayload.dstChainData,
            messagePayload.srcChainSelector,
            messagePayload.messageSender,
            messageBody
        );
    }

    function _verifyIsSenderOperator(bytes[] memory allowedOperators) internal view {
        bool isAllowedOperator = false;

        for (uint256 i = 0; i < allowedOperators.length; i++) {
            address allowedOperator = abi.decode(allowedOperators[i], (address));

            if (allowedOperator == msg.sender) {
                isAllowedOperator = true;
                break;
            }
        }

        require(isAllowedOperator, Errors.UnauthorizedOperator());
    }

    /**
     * @notice Delivers the message to the receiver contract if valid.
     * @param messageId The unique identifier of the message.
     * @param dstData The destination chain data of the message.
     * @param message The message data.
     */
    function _deliverMessage(
        bytes32 messageId,
        Types.EvmDstChainData memory dstData,
        uint24 srcChainSelector,
        bytes memory sender,
        bytes memory message
    ) internal {
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

    function _validateMessageParams(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData,
        bytes calldata message
    ) internal view {
        require(feeToken == address(0), Errors.UnsupportedFeeTokenType());
        require(dstChainData.receiver != address(0), Errors.InvalidReceiver());
        require(dstChainData.gasLimit > 0, Errors.InvalidGasLimit());
        require(message.length < CommonConstants.MESSAGE_MAX_SIZE, Errors.MessageTooLarge());
        require(!shouldFinaliseSrc, Errors.FinalityNotYetSupported());
        require(isChainSupported(dstChainSelector), Errors.InvalidDstChainSelector());
    }

    function _buildMessageId(uint24 dstChainSelector) private returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    ++s.router().nonce,
                    block.number,
                    msg.sender,
                    i_chainSelector,
                    dstChainSelector
                )
            );
    }

    function _collectMessageFee(
        uint24 dstChainSelector,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData
    ) internal {
        uint256 messageFee = _calculateMessageFee(dstChainSelector, feeToken, dstChainData);

        if (feeToken == address(0)) {
            require(msg.value >= messageFee, CommonErrors.InsufficientFee(msg.value, messageFee));
            // TODO: is it really needed?
            payable(address(this)).transfer(messageFee);
        } else {
            revert Errors.UnsupportedFeeTokenType();
        }
    }

    function _calculateMessageFee(
        uint24 dstChainSelector,
        address feeToken,
        ConceroTypes.EvmDstChainData memory dstChainData
    ) internal view returns (uint256) {
        s.PriceFeed storage priceFeedStorage = s.priceFeed();
        uint256 nativeUsdRate = priceFeedStorage.nativeUsdRate;

        uint256 baseFeeNative = CommonUtils.convertUsdBpsToNative(
            CommonConstants.CONCERO_MESSAGE_BASE_FEE_BPS_USD +
                CommonConstants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            nativeUsdRate
        );

        // dst chain gas fee
        uint256 gasFeeNative = _calculateGasFees(
            priceFeedStorage.lastGasPrices[dstChainSelector],
            dstChainData.gasLimit + priceFeedStorage.gasFeeConfig.gasOverhead,
            s.getNativeNativeRate(dstChainSelector)
        );

        // service gas fee
        uint24 baseChainSelector = priceFeedStorage.gasFeeConfig.baseChainSelector;
        uint256 serviceGasFeeNative = _calculateGasFees(
            priceFeedStorage.lastGasPrices[baseChainSelector],
            priceFeedStorage.gasFeeConfig.relayerGasLimit +
                priceFeedStorage.gasFeeConfig.verifierGasLimit,
            s.getNativeNativeRate(baseChainSelector)
        );

        uint256 totalFeeNative = baseFeeNative + gasFeeNative + serviceGasFeeNative;

        if (feeToken == address(0)) {
            return totalFeeNative;
        }

        return (totalFeeNative * nativeUsdRate) / CommonConstants.DECIMALS;
    }

    function _calculateGasFees(
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 exchangeRate
    ) private pure returns (uint256) {
        return (gasPrice * gasLimit * exchangeRate) / CommonConstants.DECIMALS;
    }

    /* @inheritdoc IConceroRouter */
    function getMessageFee(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        ConceroTypes.EvmDstChainData calldata dstChainData
    ) external view returns (uint256) {
        require(feeToken == address(0), Errors.UnsupportedFeeTokenType());
        require(!shouldFinaliseSrc, Errors.FinalityNotYetSupported());

        return _calculateMessageFee(dstChainSelector, feeToken, dstChainData);
    }

    function isChainSupported(uint24 chainSelector) public view returns (bool) {
        return s.router().isChainSupported[chainSelector];
    }

    function getMessageVersion() external pure returns (uint8) {
        return MESSAGE_VERSION;
    }
}
