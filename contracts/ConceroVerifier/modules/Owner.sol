// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Errors} from "../libraries/Errors.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {Base} from "./Base.sol";

import {console} from "forge-std/src/console.sol";

abstract contract Owner is Base {
    using SafeERC20 for IERC20;
    using s for s.Verifier;
    using s for s.PriceFeed;

    /**
     * @notice Withdraws accumulated fees to the owner for multiple tokens
     * @param tokens Array of token addresses (address(0) for native token)
     * @param amounts Array of amounts to withdraw for each token
     * @dev Only callable by contract owner
     */
    function withdrawConceroFees(
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            tokens.length == amounts.length && tokens.length > 0,
            CommonErrors.LengthMismatch()
        );

        uint256 totalNativeAmount;
        uint256 contractBalance = address(this).balance;
        uint256 operatorFees = s.operator().totalFeesEarnedNative;
        uint256 operatorDeposits = s.operator().totalDepositsNative;
        uint256 availableFees = contractBalance - (operatorFees + operatorDeposits);

        for (uint256 i = 0; i < tokens.length; ) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            require(amount > 0, CommonErrors.InvalidAmount());

            if (token == address(0)) {
                totalNativeAmount += amount;
                require(
                    totalNativeAmount <= availableFees,
                    Errors.InsufficientFee(totalNativeAmount, availableFees)
                );

                (bool success, ) = i_owner.call{value: amount}("");
                require(success, Errors.TransferFailed());
            } else {
                IERC20(token).safeTransfer(i_owner, amount);
            }

            unchecked {
                ++i;
            }
        }
    }

    function setNativeUsdRate(uint256 amount) external onlyOwner {
        s.priceFeed().nativeUsdRate = amount;
    }
}
