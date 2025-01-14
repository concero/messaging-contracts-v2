// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CLFModule} from "./CLFModule.sol";
import {ChainType} from "../Interfaces/IConceroVerifier.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ConceroVerifierStorage as s} from "./ConceroVerifierStorage.sol";

abstract contract OperatorModule is CLFModule {
    using SafeERC20 for IERC20;
    using s for s.Verifier;
    using s for s.Operator;

    /* INTERNAL FUNCTIONS */
    function registerOperator(address operator) external {
        // Step 1: Check if OP is registered with symbiotic and has enough delegated Stake
        s.operator().isAllowed[operator] = true;
        requestOperatorRegistration();
    }

    function deregisterOperator(address operator) external {
        s.operator().isAllowed[operator] = false;
    }

    function withdrawOperatorFees(address token, uint256 amount) external {
        if (token == address(0)) {
            (bool success, ) = i_owner.call{value: amount}("");
        } else {
            IERC20(token).safeTransfer(i_owner, amount);
        }
    }

    /* GETTER FUNCTIONS */
    function getRegisteredOperators(ChainType chainType) external view returns (bytes[] memory) {
        return s.operator().registeredOperators[chainType];
    }

    function getCohortsCount() external pure returns (uint8) {
        return COHORTS_COUNT;
    }
}
