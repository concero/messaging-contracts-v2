// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonConstants} from "../../common/CommonConstants.sol";
import {CommonTypes} from "../../common/CommonTypes.sol";

import {Storage as s} from "./Storage.sol";
import {Errors} from "./Errors.sol";

library Utils {
    using s for s.Operator;

    /* OPERATOR UTILS */
    function _addOperator(CommonTypes.ChainType chainType, bytes memory operatorAddress) internal {
        bytes[] storage registeredOperators = s.operator().registeredOperators[chainType];
        (bool exists, ) = _findBytesIndex(registeredOperators, operatorAddress);

        require(!exists, Errors.OperatorAlreadyRegistered());
        registeredOperators.push(operatorAddress);
    }

    function _removeOperator(
        CommonTypes.ChainType chainType,
        bytes memory operatorAddress
    ) internal {
        bytes[] storage registeredOperators = s.operator().registeredOperators[chainType];
        (bool exists, uint256 index) = _findBytesIndex(registeredOperators, operatorAddress);

        require(exists, Errors.OperatorNotRegistered());
        _removeAtIndex(registeredOperators, index);
    }

    /* INTERNAL UTILS */
    function _findBytesIndex(
        bytes[] storage array,
        bytes memory element
    ) private view returns (bool, uint256) {
        for (uint256 i = 0; i < array.length; i++) {
            if (keccak256(array[i]) == keccak256(element)) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function _removeAtIndex(bytes[] storage array, uint256 index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }
}
