// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Message as MessageLib, MessageConstants} from "../../common/libraries/Message.sol";
import {Constants} from "../../common/Constants.sol";
import {Signer} from "../../common/libraries/Signer.sol";
import {Utils as CommonUtils} from "../../common/libraries/Utils.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";
import {Errors} from "../libraries/Errors.sol";

import {IConceroClient} from "../../interfaces/IConceroClient.sol";
import {IConceroRouter, ConceroMessageDelivered, ConceroMessageReceived, ConceroMessageSent} from "../../interfaces/IConceroRouter.sol";

import {Base} from "./Base.sol";

import {console} from "forge-std/src/console.sol";

abstract contract Message is Base, IConceroRouter {
    using SafeERC20 for IERC20;
    using s for s.Router;
    using s for s.PriceFeed;

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
        Signer.ClfDonReportSubmission calldata reportSubmission,
        bytes calldata message
    ) external {
        Signer._verifyClfReportSignatures(reportSubmission);

        bytes memory messageReportResponse = Signer._extractClfReportResult(
            reportSubmission.report
        );

        (
            Types.InternalMessageConfig memory decodedMessageConfig,
            bytes32 messageId,
            bytes32 messageHashSum,
            bytes memory dstChainData
        ) = MessageLib._decodeMessage(messageReportResponse);

        require(messageHashSum == keccak256(message), Errors.InvalidMessageHashSum());

        emit ConceroMessageReceived(messageId);
        deliverMessage(messageId, dstChainData, message);
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

        require(
            !s.router().isMessageProcessed[messageId],
            Errors.MessageAlreadyProcessed(messageId)
        );
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
            Constants.OPERATOR_FEE_MESSAGE_RELAY_BPS_USD,
            s.priceFeed().nativeUsdRate
        );

        emit ConceroMessageDelivered(messageId);
    }

    /* INTERNAL FUNCTIONS */
    function _collectMessageFee(uint256 clientMessageConfig, bytes memory dstChainData) internal {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageConstants.OFFSET_FEE_TOKEN)
        );
        uint256 messageFee = _calculateMessageFee(clientMessageConfig, dstChainData, feeToken);

        if (feeToken == Types.FeeToken.native) {
            require(msg.value >= messageFee, Errors.InsufficientFee());
            payable(address(this)).transfer(messageFee);
        } else if (feeToken == Types.FeeToken.usdc) {
            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), messageFee);
        } else {
            revert Errors.UnsupportedFeeToken();
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

        uint24 dstChainSelector = uint24(clientMessageConfig >> MessageConstants.OFFSET_DST_CHAIN);

        uint256 baseFeeNative = CommonUtils.convertUsdBpsToNative(
            Constants.CONCERO_MESSAGE_BASE_FEE_BPS_USD,
            nativeUsdRate
        );

        uint256 gasPrice = s.priceFeed().lastGasPrices[dstChainSelector];
        uint256 gasFeeNative = gasPrice * evmDstChainData.gasLimit;

        uint256 adjustedGasFeeNative = ((gasFeeNative * 1e18) / 1e18) *
            s.priceFeed().nativeNativeRates[dstChainSelector];

        uint256 totalFeeNative = baseFeeNative + adjustedGasFeeNative;
        //        console.logString("Base fee native:");
        //        console.logUint(baseFeeNative);
        //
        //        console.logString("Gas price:");
        //        console.logUint(gasPrice);
        //
        //        console.logString("Gas fee native:");
        //        console.logUint(gasFeeNative);
        //
        //        console.logString("Adjusted gas fee native:");
        //        console.logUint(adjustedGasFeeNative);
        //
        //        console.logString("Total fee native:");
        //        console.logUint(totalFeeNative);

        if (feeToken == Types.FeeToken.native) {
            return totalFeeNative;
        }

        return (totalFeeNative * nativeUsdRate) / 1 ether;
    }

    function getMessageFeeNative(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageConstants.OFFSET_FEE_TOKEN)
        );
        require(feeToken == Types.FeeToken.native, Errors.UnsupportedFeeToken());
        return _calculateMessageFee(clientMessageConfig, dstChainData, feeToken);
    }

    function getMessageFeeUSDC(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageConstants.OFFSET_FEE_TOKEN)
        );
        require(feeToken == Types.FeeToken.usdc, Errors.UnsupportedFeeToken());
        return _calculateMessageFee(clientMessageConfig, dstChainData, feeToken);
    }
}
