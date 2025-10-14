// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CommonConstants} from "../../common/CommonConstants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";
import {Errors} from "../libraries/Errors.sol";

import {OperatorFeeWithdrawn, OperatorDeposited, OperatorDepositWithdrawn} from "../../interfaces/IConceroVerifier.sol";

import {CLF} from "./CLF.sol";

import {Utils} from "../libraries/Utils.sol";

abstract contract Operator is CLF {
    using SafeERC20 for IERC20;
    using s for s.Verifier;
    using s for s.Operator;

    function requestMessageReport(
        bytes32 messageId,
        bytes32 messageHashSum,
        uint24 srcChainSelector,
        bytes memory srcChainData
    ) external onlyOperator returns (bytes32) {
        s.Verifier storage verifier = s.verifier();

        bytes32 clfRequestId = verifier.clfRequestIdByMessageId[messageId];
        if (clfRequestId != bytes32(0)) {
            require(
                verifier.clfRequestStatus[clfRequestId] == Types.CLFRequestStatus.Failed,
                Errors.MessageAlreadyProcessed()
            );
        }
        return _requestMessageReport(messageId, messageHashSum, srcChainSelector, srcChainData);
    }

    /// @notice Allows an operator to withdraw their earned fees
    /// @param amount The amount of native tokens to withdraw
    /// @return success Boolean indicating if the withdrawal was successful

    // withdrawValidatorFee
    function withdrawOperatorFee(uint256 amount) external onlyOperator returns (bool success) {
        s.Operator storage s_operator = s.operator();
        uint256 currentFees = s_operator.feesEarnedNative[msg.sender];
        require(amount > 0, CommonErrors.InvalidAmount());
        require(amount <= currentFees, Errors.InsufficientFee(amount, currentFees));

        s_operator.feesEarnedNative[msg.sender] = currentFees - amount;
        s_operator.totalFeesEarnedNative -= amount;

        (success, ) = msg.sender.call{value: amount}("");
        require(success, CommonErrors.TransferFailed());

        emit OperatorFeeWithdrawn(msg.sender, amount);
        return success;
    }

    /// @notice Allows an operator to withdraw their deposit
    /// @param amount The amount of native tokens to withdraw
    /// @return success Boolean indicating if the withdrawal was successful
    function withdrawOperatorDeposit(uint256 amount) external onlyOperator returns (bool success) {
        s.Operator storage s_operator = s.operator();

        uint256 currentDeposit = s_operator.depositsNative[msg.sender];

        require(amount > 0, CommonErrors.InvalidAmount());
        require(
            amount <= currentDeposit,
            Errors.InsufficientOperatorDeposit(currentDeposit, amount)
        );

        s_operator.depositsNative[msg.sender] = currentDeposit - amount;
        s_operator.totalDepositsNative -= amount;

        (success, ) = msg.sender.call{value: amount}("");
        require(success, CommonErrors.TransferFailed());

        emit OperatorDepositWithdrawn(msg.sender, amount);
        return success;
    }

    /// @notice Allows operators to deposit native ETH as collateral
    /// @dev Implements nonReentrant guard to prevent reentrancy attacks
    /// @param operator The address of the operator making the deposit
    function operatorDeposit(address operator) external payable {
        s.Operator storage s_operator = s.operator();

        uint256 minimumDeposit = getCLFCost();
        require(
            msg.value >= minimumDeposit,
            Errors.InsufficientOperatorDeposit(msg.value, minimumDeposit)
        );
        require(operator != address(0), CommonErrors.InvalidAddress());

        s_operator.depositsNative[operator] += msg.value;
        s_operator.totalDepositsNative += msg.value;

        emit OperatorDeposited(msg.sender, msg.value);
    }

    /* INTERNAL FUNCTIONS */

    /* GETTER FUNCTIONS */

    function getOperatorDeposit(address operator) external view returns (uint256) {
        return s.operator().depositsNative[operator];
    }

    function getMinimumOperatorDeposit() external view returns (uint256) {
        return getCLFCost();
    }

    function getOperatorFeesEarned(address operator) external view returns (uint256) {
        return s.operator().feesEarnedNative[operator];
    }

    function isChainSupported(uint24 chainSelector) public view returns (bool) {
        return s.verifier().isChainSupported[chainSelector];
    }
}
