// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

struct CLFParams {
    address router;
    bytes32 donId;
    uint64 subscriptionId;
    bytes32 requestCLFMessageReportJsCodeHash;
}

library Types {
    enum CLFRequestStatus {
        NotStarted, //            0
        Pending, //               1
        Fulfilled, //             2
        Failed //                 3
    }
}
