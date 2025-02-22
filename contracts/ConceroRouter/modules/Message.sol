// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Message as MessageLib, MessageConfigBitOffsets} from "../../common/libraries/Message.sol";
import {Decoder as DecoderLib} from "../../common/libraries/Decoder.sol";
import {Utils as CommonUtils} from "../../common/libraries/Utils.sol";

import {CommonConstants} from "../../common/CommonConstants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";

import {IConceroClient} from "../../interfaces/IConceroClient.sol";
import {IConceroRouter, ConceroMessageDelivered, ConceroMessageReceived, ConceroMessageSent} from "../../interfaces/IConceroRouter.sol";

import {ClfSigner} from "./ClfSigner.sol";
import {Base} from "./Base.sol";

import {console} from "hardhat/console.sol";

library Errors {
    error UnsupportedFeeTokenType();
    error MessageAlreadyProcessed(bytes32 messageId);
    error MessageDeliveryFailed(bytes32 messageId);
    error InvalidReceiver();
    error InvalidMessageHashSum();
    error UnauthorizedOperator();
}

abstract contract Message is ClfSigner, IConceroRouter {
    using SafeERC20 for IERC20;
    using s for s.Router;
    using s for s.PriceFeed;
    using s for s.Operator;

    constructor(address conceroVerifier, uint64 conceroVerifierSubId, address[4] memory clfSigners) ClfSigner(conceroVerifier,  conceroVerifierSubId, clfSigners) {}

    function conceroSend(
        uint256 config,
        bytes calldata dstChainData,
        bytes calldata message
    ) external payable returns (bytes32) {
        _collectMessageFee(config, dstChainData);

        (bytes32 _messageId, uint256 internalMessageConfig) = MessageLib.buildInternalMessage(
            config,
            dstChainData,
            message,
            i_chainSelector,
            s.router().nonce
        );

        s.router().nonce += 1;
        //        s.router().isMessageSent[_messageId] = true;

        emit ConceroMessageSent(_messageId, internalMessageConfig, dstChainData, message);
        return _messageId;
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
            !s.router().isMessageProcessed[decodedMessageReportResult.messageId],
            Errors.MessageAlreadyProcessed(decodedMessageReportResult.messageId)
        );

        bool isAllowedOperator = false;
            for (uint256 i = 0; i < decodedMessageReportResult.allowedOperators.length; i++) {
                bytes memory operatorBytes = decodedMessageReportResult.allowedOperators[i];
                address allowedOperator = address(bytes20(operatorBytes));
                if (allowedOperator == msg.sender) {
                    isAllowedOperator = true;
                    break;
                }
            }
            require(isAllowedOperator, Errors.UnauthorizedOperator());

        emit ConceroMessageReceived(decodedMessageReportResult.messageId);
        deliverMessage(
            decodedMessageReportResult.messageId,
            decodedMessageReportResult.dstChainData,
            message
        );
    }

    /**
     * @notice Delivers the message to the receiver contract if valid.
     * @param messageId The unique identifier of the message.
     * @param _dstData The destination chain data of the message.
     * @param message The message data.
     */
    function deliverMessage(
        bytes32 messageId,
        bytes memory _dstData,
        bytes memory message
    ) internal {
        Types.EvmDstChainData memory dstData = abi.decode(_dstData, (Types.EvmDstChainData));

        s.router().isMessageProcessed[messageId] = true;

        require(dstData.receiver != address(0), Errors.InvalidReceiver());
        require(CommonUtils.isContract(dstData.receiver), Errors.InvalidReceiver());

        bytes memory callData = abi.encodeWithSelector(
            IConceroClient.conceroReceive.selector,
            messageId,
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
    function _collectMessageFee(uint256 clientMessageConfig, bytes memory dstChainData) internal {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageConfigBitOffsets.OFFSET_FEE_TOKEN)
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

    function _calculateMessageFee(
        uint256 clientMessageConfig,
        bytes memory dstChainData,
        Types.FeeToken feeToken
    ) internal view returns (uint256) {
        uint256 nativeUsdRate = s.priceFeed().nativeUsdRate;
        Types.EvmDstChainData memory evmDstChainData = abi.decode(
            dstChainData,
            (Types.EvmDstChainData)
        );

        uint24 dstChainSelector = uint24(
            clientMessageConfig >> MessageConfigBitOffsets.OFFSET_DST_CHAIN
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

    function getMessageFeeNative(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageConfigBitOffsets.OFFSET_FEE_TOKEN)
        );
        require(feeToken == Types.FeeToken.native, Errors.UnsupportedFeeTokenType());
        return _calculateMessageFee(clientMessageConfig, dstChainData, feeToken);
    }

    function getMessageFeeUSDC(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageConfigBitOffsets.OFFSET_FEE_TOKEN)
        );
        require(feeToken == Types.FeeToken.usdc, Errors.UnsupportedFeeTokenType());
        return _calculateMessageFee(clientMessageConfig, dstChainData, feeToken);
    }
}
