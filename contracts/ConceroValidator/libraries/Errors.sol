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
    error InsufficientDeposit(uint256 provided, uint256 required);
    error TransferFailed();
    error InsufficientFee(uint256 requiredAmount, uint256 availableAmount);
    error InvalidClfRequestId(bytes32 clfRequestId);
    error InvalidClfResultType();

    error NoNativeRateAvailable();
    error NoGasPriceAvailable();
    error InvalidMessageVersion();
}
