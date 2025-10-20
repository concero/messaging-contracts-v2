// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library CommonErrors {
    enum RequiredVariableUnsetType {
        NativeUSDRate, //            0
        lastGasPrice //              1
    }

    error Unauthorized();
    error LengthMismatch();
    error InvalidAmount();
    error InvalidRequest();
    error InvalidAddress();
    error TransferFailed(bytes error);
    error InsufficientFee(uint256 provided, uint256 required);
    error RequiredVariableUnset(RequiredVariableUnsetType variableType);
}
