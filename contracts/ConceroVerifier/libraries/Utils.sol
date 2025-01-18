// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ChainType} from "../../interfaces/IConceroVerifier.sol";

import {OperatorAlreadyRegistered, OperatorNotRegistered} from "../Errors.sol";
import {Storage as s} from "./Storage.sol";

library Utils {
    using s for s.Operator;

    function _addOperator(ChainType chainType, bytes memory operatorAddress) internal {
        address operator = address(bytes20(operatorAddress));
        bytes[] storage registeredOperators = s.operator().registeredOperators[chainType];

        for (uint256 i = 0; i < registeredOperators.length; i++) {
            require(
                keccak256(registeredOperators[i]) != keccak256(operatorAddress),
                OperatorAlreadyRegistered()
            );
        }

        registeredOperators.push(operatorAddress);
        s.operator().isAllowed[operator] = true;
    }

    function _removeOperator(ChainType chainType, bytes memory operatorAddress) internal {
        address operator = address(bytes20(operatorAddress));
        bytes[] storage registeredOperators = s.operator().registeredOperators[chainType];

        bool found = false;
        for (uint256 i = 0; i < registeredOperators.length; i++) {
            if (keccak256(registeredOperators[i]) == keccak256(operatorAddress)) {
                registeredOperators[i] = registeredOperators[registeredOperators.length - 1];
                registeredOperators.pop();
                found = true;
                break;
            }
        }
        require(found, OperatorNotRegistered());
        s.operator().isAllowed[operator] = false;
    }
}
