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
    error FinalisationIsNotSupportedYet();
}

abstract contract Message is ClfSigner, IConceroRouter {
    using SafeERC20 for IERC20;
    using s for s.Router;
    using s for s.PriceFeed;
    using s for s.Operator;

    uint8 private constant ROUTER_VERSION = 1;

    constructor(
        address conceroVerifier,
        uint64 conceroVerifierSubId,
        address[4] memory clfSigners
    ) ClfSigner(conceroVerifier, conceroVerifierSubId, clfSigners) {}

    function conceroSend(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        bytes calldata dstChainData,
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
            ROUTER_VERSION,
            shouldFinaliseSrc,
            dstChainSelector,
            dstChainData,
            abi.encode(msg.sender),
            message
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

    function getRouterVersion() external pure returns (uint8) {
        return ROUTER_VERSION;
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

    function _validateMessageParams(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        bytes calldata dstChainData,
        bytes calldata message
    ) internal view {
        require(feeToken == address(0), Errors.UnsupportedFeeTokenType());
        require(dstChainData.length > 0, Errors.InvalidDstChainData());
        require(message.length < CommonConstants.MESSAGE_MAX_SIZE, Errors.MessageTooLarge());
        require(!shouldFinaliseSrc, Errors.FinalisationIsNotSupportedYet());
        // require(
        //     isChainSupported(dstChainSelector),
        //     InvalidClientMessageConfig(MessageConfigErrorType.InvalidDstChainSelector)
        // );
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
        bytes memory dstChainData
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
        bytes memory dstChainData
    ) internal view returns (uint256) {
        uint256 nativeUsdRate = s.priceFeed().nativeUsdRate;
        Types.EvmDstChainData memory evmDstChainData = abi.decode(
            dstChainData,
            (Types.EvmDstChainData)
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

        if (feeToken == address(0)) {
            return totalFeeNative;
        }

        return (totalFeeNative * nativeUsdRate) / 1e18;
    }

    function getMessageFee(
        uint24 dstChainSelector,
        bool shouldFinaliseSrc,
        address feeToken,
        bytes calldata dstChainData
    ) external view returns (uint256) {
        require(feeToken == address(0), Errors.UnsupportedFeeTokenType());
        require(!shouldFinaliseSrc, Errors.FinalisationIsNotSupportedYet());

        return _calculateMessageFee(dstChainSelector, feeToken, dstChainData);
    }

    function isChainSupported(uint24 chainSelector) public view returns (bool) {
        return s.router().isChainSupported[chainSelector];
    }
}
