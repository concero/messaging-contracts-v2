// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {CLFModule} from "./CLFModule.sol";
import {ChainType, MessageReportRequest, OperatorRegistrationAction, OperatorFeeWithdrawn, OperatorDeposited, OperatorRegistered, OperatorDeregistered, FeeTokenType} from "../Interfaces/IConceroVerifier.sol";
import {ConceroVerifierStorage as s} from "./ConceroVerifierStorage.sol";
import {CommonConstants} from "../Common/CommonConstants.sol";
import {LengthMismatch} from "../Common/Errors.sol";
import {MessageAlreadyProcessed, InsufficientOperatorDeposit, OperatorNotFound, InvalidEVMAddress} from "./Errors.sol";

abstract contract OperatorModule is CLFModule {
    using SafeERC20 for IERC20;
    using s for s.Verifier;
    using s for s.Operator;

    function requestMessageReport(MessageReportRequest calldata request) external onlyOperator {
        require(!s.verifier().pendingMessageReports[request.messageId], MessageAlreadyProcessed());
        s.verifier().pendingMessageReports[request.messageId] = true;
        _requestMessageReport(request);
    }

    /**
     * @dev Registers an operator for specific chain types with the provided addresses.
     * @param chainTypes The chain types for which the operator is registering.
     * @param operatorAddresses The corresponding operator addresses.
     */
    function registerOperator(
        ChainType[] calldata chainTypes,
        OperatorRegistrationAction[] calldata operatorActions,
        bytes[] calldata operatorAddresses
    ) external {
        require(chainTypes.length == operatorAddresses.length, LengthMismatch());

        for (uint256 i = 0; i < chainTypes.length; i++) {
            ChainType chainType = chainTypes[i];
            bytes memory operatorAddress = operatorAddresses[i];

            if (chainType == ChainType.EVM) {
                require(operatorAddress.length == 20, InvalidEVMAddress());
                s.operator().registeredOperators[ChainType.EVM].push(operatorAddress);
                emit OperatorRegistered(ChainType.EVM, operatorAddress);
            }
            // Later:
            //            else {
            //                require(operatorAddress.length > 0, InvalidNonEVMAddress());
            //                s.operator().registeredOperators[chainType].push(operatorAddress);
            //                emit OperatorRegistered(chainType, operatorAddress);
            //            }
        }
        // s.operator().isAllowed[msg.sender] = true;
        _requestOperatorRegistration();
    }

    /**
     * @dev Deregisters an operator for specific chain types with the provided addresses.
     * @param chainTypes The chain types for which the operator is deregistering.
     * @param operatorAddresses The corresponding operator addresses.
     */
    // function deregisterOperator(
    //     ChainType[] calldata chainTypes,
    //     bytes[] calldata operatorAddresses
    // ) external {
    //     require(chainTypes.length == operatorAddresses.length, LengthMismatch());

    //     for (uint256 i = 0; i < chainTypes.length; i++) {
    //         ChainType chainType = chainTypes[i];
    //         bytes memory operatorAddress = operatorAddresses[i];

    //         if (chainType == ChainType.EVM) {
    //             require(operatorAddress.length == 20, InvalidEVMAddress());
    //             _removeOperator(chainType, operatorAddress);
    //             emit OperatorDeregistered(ChainType.EVM, operatorAddress);
    //         }
    //         // later:
    //         //            else {
    //         //                require(operatorAddress.length > 0, InvalidNonEVMAddress());
    //         //                _removeOperator(chainType, operatorAddress);
    //         //                emit OperatorDeregistered(chainType, operatorAddress);
    //         //            }
    //     }
    //     s.operator().isAllowed[msg.sender] = false;
    //     _requestOperatorDeregistration();
    // }

    /**
     * @dev Internal function to remove an operator from the registered list.
     * @param chainType The chain type for the operator.
     * @param operatorAddress The address of the operator to be removed.
     */
    function _removeOperator(ChainType chainType, bytes memory operatorAddress) internal {
        bytes[] storage operators = s.operator().registeredOperators[chainType];
        uint256 length = operators.length;

        for (uint256 i = 0; i < length; i++) {
            if (keccak256(operators[i]) == keccak256(operatorAddress)) {
                operators[i] = operators[length - 1];
                operators.pop();
                return;
            }
        }

        revert OperatorNotFound();
    }

    function withdrawOperatorFee(FeeTokenType tokenType, uint256 amount) external onlyOperator {
        //todo: using native only for now
        if (tokenType == FeeTokenType.native) {
            (bool success, ) = i_owner.call{value: amount}("");
        }
        //        else if (tokenType == FeeTokenType.USDC) {
        //            IERC20(token).safeTransfer(i_owner, amount);
        //        }
        emit OperatorFeeWithdrawn(msg.sender, amount);
    }

    function operatorDeposit(uint256 amount) external {
        IERC20(i_USDC).safeTransferFrom(msg.sender, address(this), amount);
        s.operator().deposit[msg.sender] += amount;
        emit OperatorDeposited(msg.sender, amount);
    }

    /* INTERNAL FUNCTIONS */

    /* GETTER FUNCTIONS */
    function getRegisteredOperators(ChainType chainType) external view returns (bytes[] memory) {
        return s.operator().registeredOperators[chainType];
    }

    function getCohortsCount() external pure returns (uint8) {
        return CommonConstants.COHORTS_COUNT;
    }

    function getOperatorDeposit(address operator) external view returns (uint256) {
        return s.operator().deposit[operator];
    }

    function getOperatorFeesEarned(address operator) external view returns (uint256, uint256) {
        return (s.operator().feesEarnedNative[operator], s.operator().feesEarnedUSDC[operator]);
    }
}
