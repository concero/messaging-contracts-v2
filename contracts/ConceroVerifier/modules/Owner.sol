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

abstract contract Owner is Base {
    using SafeERC20 for IERC20;
    using s for s.Verifier;
    using s for s.Config;

    /**
     * @notice Calculates the amount of native token fees available for withdrawal
     * @return availableFees Amount of native token fees that can be withdrawn
     */
    function getWithdrawableConceroFee() public view returns (uint256 availableFees) {
        s.Operator storage s_operator = s.operator();

		uint256 totalNativeDebt = s_operator.totalFeesEarnedNative + s_operator.totalDepositsNative;
		uint256 verifierBalance = address(this).balance;

		// We charge the operator a fee for successful reports + gas compensation for CLF work,
		// so the current balance of ConceroVerifier may be less than the total debt amount
        if (verifierBalance > totalNativeDebt) {
            return verifierBalance - totalNativeDebt;
		}

        return 0;
    }

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
        uint256 availableFees = getWithdrawableConceroFee();

        for (uint256 i = 0; i < tokens.length; ) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            require(amount > 0, CommonErrors.InvalidAmount());

            if (token == address(0)) {
                totalNativeAmount += amount;
                require(
                    totalNativeAmount <= availableFees,
                    CommonErrors.InsufficientFee(totalNativeAmount, availableFees)
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

    /**
     * @notice Set support status for multiple chains at once
     * @param chainSelectors Array of chain selectors to update
     * @param isSupported Array of boolean values indicating support status for each corresponding chain selector
     */
    function setSupportedChains(
        uint24[] calldata chainSelectors,
        bool[] calldata isSupported
    ) external onlyOwner {
        s.Verifier storage s_verifier = s.verifier();

        require(chainSelectors.length == isSupported.length, CommonErrors.LengthMismatch());

        for (uint256 index = 0; index < chainSelectors.length; index++) {
            s_verifier.isChainSupported[chainSelectors[index]] = isSupported[index];
        }
    }

    function setGasFeeConfig(
        uint32 vrfMsgReportRequestGasOverhead,
        uint32 clfGasPriceOverEstimationBps,
        uint32 clfCallbackGasOverhead,
        uint32 clfCallbackGasLimit
    ) external onlyOwner {
        s.config().gasFeeConfig = s.GasFeeConfig(
            vrfMsgReportRequestGasOverhead,
            clfGasPriceOverEstimationBps,
            clfCallbackGasOverhead,
            clfCallbackGasLimit,
            0
        );
    }
}
