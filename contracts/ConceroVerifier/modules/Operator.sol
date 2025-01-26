// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Constants} from "../../common/Constants.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {Utils as CommonUtils} from "../../common/libraries/Utils.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Types} from "../libraries/Types.sol";
import {Errors} from "../libraries/Errors.sol";

import {OperatorFeeWithdrawn, OperatorDeposited} from "../../interfaces/IConceroVerifier.sol";

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

    function withdrawOperatorFee(
        Types.FeeTokenType tokenType,
        uint256 amount
    ) external onlyOperator {
        //todo: using native only for now
        if (tokenType == Types.FeeTokenType.native) {
            (bool success, ) = i_owner.call{value: amount}("");
        }
        //        else if (tokenType == FeeTokenType.USDC) {
        //            IERC20(token).safeTransfer(i_owner, amount);
        //        }
        emit OperatorFeeWithdrawn(msg.sender, amount);
    }

    function operatorDeposit() external payable // nonReentrant
    {
        // Calculate minimum deposit in native currency based on configured USD BPS
        uint256 minimumDepositNative = CommonUtils.convertUSDBPSToNative(
            Constants.OPERATOR_DEPOSIT_MINIMUM_BPS_USD,
            s.priceFeed().nativeUsdRate
        );

        // Check if deposit meets minimum requirement
        if (msg.value < minimumDepositNative) {
            revert Errors.InsufficientOperatorDeposit();
        }

        // Update operator's deposit balance before transfer
        s.operator().depositNative[msg.sender] += msg.value;

        // Use call instead of transfer for better gas efficiency and compatibility
        (bool success, ) = i_owner.call{value: msg.value}("");
        if (!success) {
            revert Errors.NativeTransferFailed();
        }

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
        return s.operator().depositNative[operator];
    }

    function getOperatorFeesEarned(address operator) external view returns (uint256) {
        return s.operator().feesEarnedNative[operator];
    }
}
