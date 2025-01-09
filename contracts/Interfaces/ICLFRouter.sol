// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

interface ICLFRouter {
    enum CLFRequestStatus {
        NotStarted,
        Pending,
        FulFilled
    }
}
