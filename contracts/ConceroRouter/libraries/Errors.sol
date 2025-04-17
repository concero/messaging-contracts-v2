// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Errors {
    error MessageAlreadyProcessed(bytes32 messageId);
    error MessageDeliveryFailed(bytes32 messageId);
    error InvalidReceiver();
    error InvalidMessageHashSum();
    error UnsupportedChainSelector(uint24 chainSelector);
}
