// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {MessageLib} from "../Libraries/MessageLib.sol";
import {SignerLib} from "../Libraries/SignerLib.sol";
import {ConceroRouterStorage as s} from "./ConceroRouterStorage.sol";
import {UnsupportedFeeToken, InsufficientFee, MessageAlreadyProcessed, InvalidReceiver} from "./Errors.sol";
import {OnlyAllowedOperator, OnlyOwner} from "../Common/Errors.sol";
import {ClientMessageRequest, InternalMessage, EvmSrcChainData, EvmDstChainData, ClientMessage, InternalMessageConfig} from "../Common/MessageTypes.sol";
import {SupportedChains} from "../Libraries/SupportedChains.sol";
import {IConceroRouter} from "../Interfaces/IConceroRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConceroClient} from "../Interfaces/IConceroClient.sol";

contract ConceroRouter is IConceroRouter {
    using SafeERC20 for IERC20;
    using s for s.Router;

    /* IMMUTABLE VARIABLES */
    address internal immutable i_owner;
    uint24 internal immutable i_chainSelector;
    address internal immutable i_USDC;

    /* MODIFIERS */
    modifier onlyOwner() {
        require(msg.sender == i_owner, OnlyOwner());
        _;
    }

    constructor(uint24 chainSelector, address owner) {
        i_chainSelector = chainSelector;
        i_owner = owner;
    }

    function sendConceroMessage(ClientMessageRequest calldata req) external payable {
        _collectMessageFee(req);

        InternalMessage memory message = MessageLib.buildInternalMessage(
            req,
            abi.encode(EvmSrcChainData({sender: msg.sender, blockNumber: block.number})),
            s.router().nonce
        );
        //        emit ConceroMessageSent(messageId, message);
    }

    /**
     * @notice Submits a message report, verifies the signatures, and processes the report data.
     * @param reportSubmission the serialized report data.
     * @param message the message data.
     */
    function submitMessageReport(
        SignerLib.ClfDonReportSubmission calldata reportSubmission,
        InternalMessage calldata message
    ) external {
        require(
            !s.router().isMessageProcessed[message.messageId],
            MessageAlreadyProcessed(message.messageId)
        );
        s.router().isMessageProcessed[message.messageId] = true;

        // Step 1: Recover and verify the signatures
        SignerLib._verifyClfReportSignatures(reportSubmission);

        // Step 2: Decode the report data
        (bytes32 messageId, bytes32 messageHash) = SignerLib._extractClfResponse(
            reportSubmission.report
        );

        // Step 3: validate and decode message
        (
            InternalMessageConfig memory decodedMessageConfig,
            EvmSrcChainData memory srcData, //not used
            EvmDstChainData memory dstData,
            bytes memory payload
        ) = MessageLib.decodeMessage(message);

        // Step 4: Deliver the message
        deliverMessage(messageId, dstData, payload);
    }

    /**
     * @notice Delivers the message to the receiver contract if valid.
     * @param messageId The unique identifier of the message.
     * @param dstData The destination chain data of the message.
     * @param payload The actual payload of the message.
     */
    function deliverMessage(
        bytes32 messageId,
        EvmDstChainData memory dstData,
        bytes memory payload
    ) internal {
        ClientMessage memory clientMessage = ClientMessage({
            messageId: messageId,
            message: payload
        });

        require(dstData.receiver != address(0), InvalidReceiver());
        require(isContract(dstData.receiver), InvalidReceiver());

        (bool success, bytes memory reason) = dstData.receiver.call{gas: dstData.gasLimit}(
            abi.encodeWithSelector(IConceroClient.ConceroReceive.selector, clientMessage)
        );

        if (!success) {
            if (reason.length > 0) {
                revert(string(reason));
            } else {
                revert("ConceroReceive call failed");
            }
        }
    }

    /**
     * @notice Checks if the provided address is a contract.
     * @param addr The address to check.
     * @return bool True if the address is a contract, false otherwise.
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getMessageFee(ClientMessageRequest calldata message) public view returns (uint256) {
        uint256 valueTransferFee = 0;
        // should decode config to get feetoken
        return 1;
        //        for (uint256 i = 0; i < message.tokenAmounts.length; i++) {
        //            valueTransferFee += message.tokenAmounts[i].amount / CONCERO_VALUE_TRANSFER_FEE_FACTOR;
        //        }

        //        if (message.feeToken == address(0)) {
        //            return 50_000 + valueTransferFee;
        //        } else if (message.feeToken == i_USDC) {
        //            return 50_000 + valueTransferFee;
        //        } else {
        //            revert UnsupportedFeeToken();
        //        }
    }

    function isChainSupported(uint24 chainSelector) external view returns (bool) {
        return SupportedChains.isChainSupported(chainSelector);
    }

    /* OWNER FUNCTIONS */
    //    function registerOperator(address operator) external payable onlyOwner {
    //        s.router().isAllowedOperator[operator] = true;
    //    }
    //
    //    function deregisterOperator(address operator) external payable onlyOwner {
    //        s.router().isAllowedOperator[operator] = false;
    //    }

    function withdrawFees(address token, uint256 amount) external payable onlyOwner {
        if (token == address(0)) {
            (bool success, ) = i_owner.call{value: amount}("");
        } else {
            IERC20(token).safeTransfer(i_owner, amount);
        }
    }

    /* INTERNAL FUNCTIONS */
    function _collectMessageFee(ClientMessageRequest calldata message) internal {
        //todo: maybe get rid of ClientMessageRequest.feetoken
        //        uint256 feePayable = getMessageFee(message);
        //
        //        if (message.feeToken == i_USDC) {
        //            IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), feePayable);
        //        } else if (message.feeToken == address(0)) {
        //            require(msg.value == feePayable, InsufficientFee());
        //        }
    }
}
