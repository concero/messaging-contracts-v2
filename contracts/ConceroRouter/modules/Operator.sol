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
import {Storage as s} from "../libraries/Storage.sol";

import {OperatorFeeWithdrawn} from "../../interfaces/IConceroRouter.sol";

import {Base} from "./Base.sol";

abstract contract Operator is Base {
    using SafeERC20 for IERC20;
    using s for s.Operator;

    function withdrawOperatorFee(uint256 amount) external returns (bool success) {
        uint256 currentFees = s.operator().feesEarnedNative[msg.sender];
        require(amount > 0, CommonErrors.InvalidAmount());
        require(amount <= currentFees, CommonErrors.InsufficientFee(amount, currentFees));

        s.operator().feesEarnedNative[msg.sender] = currentFees - amount;
        s.operator().totalFeesEarnedNative -= amount;

        (success, ) = msg.sender.call{value: amount}("");
        require(success, CommonErrors.TransferFailed());

        emit OperatorFeeWithdrawn(msg.sender, amount);
    }

    /* GETTER FUNCTIONS */

    function getCohort(address operator) external pure returns (uint8) {
        return uint8(uint160(operator) % CommonConstants.COHORTS_COUNT);
    }
}
