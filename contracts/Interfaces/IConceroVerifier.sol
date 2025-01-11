// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

enum CLFRequestStatus {
    NotStarted, // 0
    Pending, // 1
    FulFilled // 2
}

interface IConceroVerifier {}
