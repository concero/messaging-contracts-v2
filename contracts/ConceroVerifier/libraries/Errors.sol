// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Errors {
    error MessageAlreadyProcessed();
    error InvalidEVMAddress();
    error UnauthorizedOperator();
    error OperatorNotFound();
    error InsufficientOperatorDeposit(uint256 provided, uint256 required);
    error OperatorAlreadyRegistered();
    error OperatorNotRegistered();
    error OperatorAddressMismatch();
    error TransferFailed();
    error InsufficientFee(uint256 requiredAmount, uint256 availableAmount);

    error NoNativeRateAvailable();
    error NoGasPriceAvailable();
    error InvalidMessageVersion();
}
