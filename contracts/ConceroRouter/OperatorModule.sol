// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BaseModule} from "./BaseModule.sol";
import {SupportedChains} from "../Libraries/SupportedChains.sol";
import {CommonConstants} from "../Common/CommonConstants.sol";

abstract contract OperatorModule is BaseModule {
    using SafeERC20 for IERC20;

    function withdrawOperatorFees(address token, uint256 amount) external {
        if (token == address(0)) {
            (bool success, ) = i_owner.call{value: amount}("");
        } else {
            IERC20(token).safeTransfer(i_owner, amount);
        }
    }

    /* GETTER FUNCTIONS */
    function isChainSupported(uint24 chainSelector) external view returns (bool) {
        return SupportedChains.isChainSupported(chainSelector);
    }

    function getCohort(address operator) external view returns (uint8) {
        return uint8(uint160(operator) % CommonConstants.COHORTS_COUNT);
    }
}
