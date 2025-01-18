// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Message as MessageLib, MessageLibConstants} from "../../common/libraries/Message.sol";
import {Signer} from "../../common/libraries/Signer.sol";
import {Utils} from "../../common/libraries/Utils.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Errors} from "../libraries/Errors.sol";
import {Types} from "../libraries/Types.sol";

import {IConceroClient} from "../../interfaces/IConceroClient.sol";
import {IConceroRouter} from "../../interfaces/IConceroRouter.sol";

import {Base} from "./Base.sol";

abstract contract Message is Base, IConceroRouter {
    using SafeERC20 for IERC20;
    using s for s.Router;
    using s for s.PriceFeed;

    function conceroSend(
        uint256 config,
        bytes calldata dstChainData,
        bytes calldata message
    ) external payable returns (bytes32 messageId) {
        _collectMessageFee(config, dstChainData);

        (bytes32 _messageId, uint256 internalMessageConfig) = MessageLib.buildInternalMessage(
            config,
            dstChainData,
            message,
            i_chainSelector,
            s.router().nonce
        );

        s.router().nonce += 1;

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
        // Step 1: Recover and verify the signatures
        Signer._verifyClfReportSignatures(reportSubmission);

        // Step 2: Decode the report data
        //        (InternalMessageConfig memory decodedMessageConfig, bytes32 messageId, bytes32 messageHashSum, bytes memory srcData, bytes memory dstData) = Signer.sol._extractClfResponse(
        //            reportSubmission.report
        //        );
        //        require(
        //            !s.router().isMessageProcessed[messageId],
        //            MessageAlreadyProcessed(messageId)
        //        );
        //        s.router().isMessageProcessed[messageId] = true;

        // Step 3: Deliver the message
        //        emit ConceroMessageReceived(messageId);
        //        deliverMessage(messageId, dstData, message);
    }

    /**
     * @notice Delivers the message to the receiver contract if valid.
     * @param messageId The unique identifier of the message.
     * @param dstData The destination chain data of the message.
     * @param message The message data.
     */
    function deliverMessage(
        bytes32 messageId,
        Types.EvmDstChainData memory dstData,
        bytes memory message
    ) internal {
        require(dstData.receiver != address(0), Errors.InvalidReceiver());
        require(Utils.isContract(dstData.receiver), Errors.InvalidReceiver());

        (bool success, bytes memory reason) = dstData.receiver.call{gas: dstData.gasLimit}(
            abi.encodeWithSelector(IConceroClient.conceroReceive.selector, messageId, message)
        );

        if (!success) {
            if (reason.length > 0) {
                revert(string(reason));
            } else {
                revert("ConceroReceive call failed");
            }
        }

        emit ConceroMessageDelivered(messageId);
    }

    /* INTERNAL FUNCTIONS */
    function _collectMessageFee(uint256 clientMessageConfig, bytes memory dstChainData) internal {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageLibConstants.OFFSET_FEE_TOKEN)
        );
        uint256 messageFee = _calculateMessageFee(clientMessageConfig, dstChainData);

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
        bytes memory dstChainData
    ) internal view returns (uint256) {
        Types.EvmDstChainData memory evmDstChainData = abi.decode(
            dstChainData,
            (Types.EvmDstChainData)
        );

        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageLibConstants.OFFSET_FEE_TOKEN)
        );
        uint24 dstChainSelector = uint24(
            clientMessageConfig >> MessageLibConstants.OFFSET_DST_CHAIN
        );
        uint256 baseFee = 0.01 ether;
        uint256 gasPrice = s.priceFeed().lastGasPrices[dstChainSelector];
        uint256 gasFeeNative = gasPrice * evmDstChainData.gasLimit;
        uint256 adjustedGasFeeNative = (gasFeeNative *
            s.priceFeed().nativeNativeRates[dstChainSelector]) / 1 ether;
        uint256 totalFeeNative = baseFee + adjustedGasFeeNative;

        if (feeToken == Types.FeeToken.usdc) {
            return (totalFeeNative * s.priceFeed().nativeUsdcRate) / 1 ether;
        } else if (feeToken == Types.FeeToken.native) {
            return totalFeeNative;
        } else {
            revert Errors.UnsupportedFeeToken();
        }
    }

    function getMessageFeeNative(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageLibConstants.OFFSET_FEE_TOKEN)
        );
        require(feeToken == Types.FeeToken.native, Errors.UnsupportedFeeToken());
        return _calculateMessageFee(clientMessageConfig, dstChainData);
    }

    function getMessageFeeUSDC(
        uint256 clientMessageConfig,
        bytes memory dstChainData
    ) external view returns (uint256) {
        Types.FeeToken feeToken = Types.FeeToken(
            uint8(clientMessageConfig >> MessageLibConstants.OFFSET_FEE_TOKEN)
        );
        require(feeToken == Types.FeeToken.usdc, Errors.UnsupportedFeeToken());
        return _calculateMessageFee(clientMessageConfig, dstChainData);
    }
}
