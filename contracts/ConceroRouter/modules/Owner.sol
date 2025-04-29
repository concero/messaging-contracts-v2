// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Base} from "./Base.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Storage as s} from "../libraries/Storage.sol";
import {Errors} from "../libraries/Errors.sol";

abstract contract Owner is Base {
    using SafeERC20 for IERC20;
    using s for s.PriceFeed;
    using s for s.Operator;

    address immutable i_feedUpdater;

    constructor(address _feedUpdater) {
        i_feedUpdater = _feedUpdater;
    }

    modifier onlyFeedUpdater() {
        require(msg.sender == i_feedUpdater || msg.sender == i_owner, CommonErrors.Unauthorized());
        _;
    }

    /**
     * @notice Calculates the amount of native token fees available for withdrawal
     * @return availableFees Amount of native token fees that can be withdrawn
     */
    function getWithdrawableConceroFee() public view returns (uint256) {
        return address(this).balance - (s.operator().totalFeesEarnedNative);
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
                require(success, CommonErrors.TransferFailed());
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
        require(chainSelectors.length == isSupported.length, CommonErrors.LengthMismatch());

        for (uint256 index; index < chainSelectors.length; ++index) {
            s.router().isChainSupported[chainSelectors[index]] = isSupported[index];
        }
    }

    function setNativeUsdRate(uint256 amount) external onlyFeedUpdater {
        s.priceFeed().nativeUsdRate = amount;
    }

    function setNativeNativeRates(
        uint24[] memory dstChainSelectors,
        uint256[] memory rates
    ) external onlyFeedUpdater {
        require(dstChainSelectors.length == rates.length, CommonErrors.LengthMismatch());
        for (uint256 i = 0; i < dstChainSelectors.length; i++) {
            require(
                s.router().isChainSupported[dstChainSelectors[i]],
                Errors.UnsupportedChainSelector(dstChainSelectors[i])
            );
            s.priceFeed().nativeNativeRates[dstChainSelectors[i]] = rates[i];
        }
    }

    function setLastGasPrices(
        uint24[] memory dstChainSelectors,
        uint256[] memory gasPrices
    ) external onlyFeedUpdater {
        require(dstChainSelectors.length == gasPrices.length, CommonErrors.LengthMismatch());

        s.PriceFeed storage priceFeedStorage = s.priceFeed();

        for (uint256 i = 0; i < dstChainSelectors.length; i++) {
            priceFeedStorage.lastGasPrices[dstChainSelectors[i]] = gasPrices[i];
        }
    }
}
