// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CommonErrors} from "../../common/CommonErrors.sol";
import {Storage as s} from "../libraries/Storage.sol";

import {Base} from "./Base.sol";

abstract contract Owner is Base {
    using SafeERC20 for IERC20;
    using s for s.PriceFeed;

    function withdrawConceroFees(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = i_owner.call{value: amount}("");
        } else {
            IERC20(token).safeTransfer(i_owner, amount);
        }
    }

    function setNativeUsdRate(uint256 amount) external onlyOwner {
        s.priceFeed().nativeUsdRate = amount;
    }

    function setNativeNativeRates(
        uint24[] memory dstChainSelectors,
        uint256[] memory rates
    ) external onlyOwner {
        require(dstChainSelectors.length == rates.length, CommonErrors.LengthMismatch());
        for (uint256 i = 0; i < dstChainSelectors.length; i++) {
            s.priceFeed().nativeNativeRates[dstChainSelectors[i]] = rates[i];
        }
    }

    function setLastGasPrices(
        uint24[] memory dstChainSelectors,
        uint256[] memory gasPrices
    ) external onlyOwner {
        require(dstChainSelectors.length == gasPrices.length, CommonErrors.LengthMismatch());
        for (uint256 i = 0; i < dstChainSelectors.length; i++) {
            s.priceFeed().lastGasPrices[dstChainSelectors[i]] = gasPrices[i];
        }
    }
}
