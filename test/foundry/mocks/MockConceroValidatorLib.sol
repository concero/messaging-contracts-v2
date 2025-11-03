// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IValidatorLib} from "../../../contracts/interfaces/IValidatorLib.sol";
import {IConceroRouter} from "../../../contracts/interfaces/IConceroRouter.sol";

contract MockConceroValidatorLib is IValidatorLib {
    uint256 internal s_validationFeeInNative = 0.01 ether;

    function isValid(bytes calldata, bytes calldata) external view returns (bool) {
        return true;
    }

    function getFee(IConceroRouter.MessageRequest calldata) external view returns (uint256) {
        return s_validationFeeInNative;
    }

    function getDstLib(uint24) external view returns (bytes memory) {
        return abi.encodePacked(address(this));
    }

    function setValidationFeeInNative(uint256 feeInNative) external {
        s_validationFeeInNative = feeInNative;
    }
}
