// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {IValidatorLib} from "../../../contracts/interfaces/IValidatorLib.sol";
import {IConceroRouter} from "../../../contracts/interfaces/IConceroRouter.sol";
import {ValidatorCodec} from "../../../contracts/common/libraries/ValidatorCodec.sol";

contract MockConceroValidatorLib is IValidatorLib {
    enum ValidationBehavior {
        ReturnTrue, // returns true (default)
        ReturnFalse, // returns 0 (false)
        Revert, // reverts
        InvalidLength // returns data with length != 32 bytes
    }

    uint256 internal s_validationFeeInNative = 0.01 ether;
    ValidationBehavior public behavior = ValidationBehavior.ReturnTrue;

    error ValidationRevert();

    function isValid(bytes calldata, bytes calldata) external view returns (bool) {
        if (behavior == ValidationBehavior.Revert) {
            revert ValidationRevert();
        } else if (behavior == ValidationBehavior.InvalidLength) {
            // Return data with an invalid length (16 bytes instead of 32)
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, 0x1234567890abcdef)
                return(ptr, 16)
            }
        } else if (behavior == ValidationBehavior.ReturnFalse) {
            return false;
        }
        return true;
    }

    function getFeeAndValidatorConfig(
        IConceroRouter.MessageRequest calldata messageRequest
    ) external view returns (uint256, bytes memory) {
        return (getFee(messageRequest), getValidatorConfig(messageRequest));
    }

    function getValidatorConfig(
        IConceroRouter.MessageRequest calldata
    ) public view virtual returns (bytes memory) {
        return ValidatorCodec.encodeEvmConfig(100_000);
    }

    function isFeeTokenSupported(address) public pure returns (bool) {
        return true;
    }

    function getFee(IConceroRouter.MessageRequest calldata) public view returns (uint256) {
        return s_validationFeeInNative;
    }

    function getDstLib(uint24) external view returns (bytes memory) {
        return abi.encodePacked(address(this));
    }

    function setValidationFeeInNative(uint256 feeInNative) external {
        s_validationFeeInNative = feeInNative;
    }

    function setBehavior(ValidationBehavior _behavior) external {
        behavior = _behavior;
    }
}
