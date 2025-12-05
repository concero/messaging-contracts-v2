// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library CommonErrors {
    error Unauthorized();
    error LengthMismatch(uint256, uint256);
    error InvalidAmount();
    error InvalidAddress();
    error FeeTokenNotSupported(address feeToken);
}
