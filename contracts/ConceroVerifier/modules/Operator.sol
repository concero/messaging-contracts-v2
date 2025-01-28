// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
import {console} from "forge-std/src/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Constants} from "../../common/Constants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";
import {Errors} from "../libraries/Errors.sol";

import {OperatorFeeWithdrawn, OperatorDeposited, OperatorDepositWithdrawn} from "../../interfaces/IConceroVerifier.sol";

import {CLF} from "./CLF.sol";

abstract contract Operator is CLF {
    using SafeERC20 for IERC20;
    using s for s.Verifier;
    using s for s.Operator;

    function requestMessageReport(
        Types.MessageReportRequest calldata request
    ) external onlyOperator {
        require(
            !s.verifier().pendingMessageReports[request.messageId],
            Errors.MessageAlreadyProcessed()
        );
        s.verifier().pendingMessageReports[request.messageId] = true;
        _requestMessageReport(request);
    }

    /**
     * @dev Registers an operator for specific chain types with the provided addresses.
     * @param chainTypes The chain types for which the operator is registering.
     * @param operatorAddresses The corresponding operator addresses.
     */
    function requestOperatorRegistration(
        Types.ChainType[] calldata chainTypes,
        Types.OperatorRegistrationAction[] calldata operatorActions,
        bytes[] calldata operatorAddresses
    ) external {
        require(
            chainTypes.length == operatorActions.length &&
                chainTypes.length == operatorAddresses.length,
            CommonErrors.LengthMismatch()
        );

        _requestOperatorRegistration(chainTypes, operatorActions, operatorAddresses);
    }

    /// @notice Allows an operator to withdraw their earned fees
    /// @param amount The amount of native tokens to withdraw
    /// @return success Boolean indicating if the withdrawal was successful
    function withdrawOperatorFee(
        uint256 amount
    )
        external
        onlyOperator
        returns (
            // nonReentrant
            bool success
        )
    {
        uint256 currentFees = s.operator().feesEarnedNative[msg.sender];
        require(amount > 0, CommonErrors.InvalidAmount());
        require(amount <= currentFees, Errors.InsufficientFee(amount, currentFees));

        s.operator().feesEarnedNative[msg.sender] = currentFees - amount;
        s.operator().totalFeesEarnedNative -= amount;

        (success, ) = msg.sender.call{value: amount}("");
        require(success, CommonErrors.TransferFailed());

        emit OperatorFeeWithdrawn(msg.sender, amount);
        return success;
    }

    /// @notice Allows an operator to withdraw their deposit
    /// @param amount The amount of native tokens to withdraw
    /// @return success Boolean indicating if the withdrawal was successful
    function withdrawOperatorDeposit(uint256 amount) external onlyOperator returns (bool success) {
        uint256 currentDeposit = s.operator().depositsNative[msg.sender];

        require(amount > 0, CommonErrors.InvalidAmount());
        require(
            amount <= currentDeposit,
            Errors.InsufficientOperatorDeposit(amount, currentDeposit)
        );

        s.operator().depositsNative[msg.sender] = currentDeposit - amount;
        s.operator().totalDepositsNative -= amount;

        (success, ) = msg.sender.call{value: amount}("");
        require(success, CommonErrors.TransferFailed());

        emit OperatorDepositWithdrawn(msg.sender, amount);
        return success;
    }

    /// @notice Allows operators to deposit native ETH as collateral
    /// @dev Implements nonReentrant guard to prevent reentrancy attacks
    /// @param operator The address of the operator making the deposit
    function operatorDeposit(
        address operator // nonReentrant
    ) external payable {
        uint256 minimumDeposit = getCLFDeposit();
        require(
            msg.value >= minimumDeposit,
            Errors.InsufficientOperatorDeposit(msg.value, minimumDeposit)
        );
        require(operator != address(0), CommonErrors.InvalidAddress());
        require(s.operator().isAllowed[operator], Errors.OperatorNotRegistered());

        s.operator().depositsNative[operator] += msg.value;
        s.operator().totalDepositsNative += msg.value;

        emit OperatorDeposited(msg.sender, msg.value);
    }

    /* INTERNAL FUNCTIONS */

    /* GETTER FUNCTIONS */
    function getRegisteredOperators(
        Types.ChainType chainType
    ) external view returns (bytes[] memory) {
        return s.operator().registeredOperators[chainType];
    }

    function getCohortsCount() external pure returns (uint8) {
        return Constants.COHORTS_COUNT;
    }

    function getOperatorDeposit(address operator) external view returns (uint256) {
        return s.operator().depositsNative[operator];
    }

    function getOperatorFeesEarned(address operator) external view returns (uint256) {
        return s.operator().feesEarnedNative[operator];
    }
}
