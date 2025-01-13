// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

enum ChainType {
    EVM,
    NON_EVM
}

enum CLFRequestType {
    RequestCLFMessageReport
}

enum CLFRequestStatus {
    NotStarted,
    Pending,
    FulFilled
}

enum ReportType {
    MessageReport,
    Other
}

struct MessageReportResult {
    uint8 version;
    ReportType reportType;
    address operator;
    bytes32 internalMessageConfig;
    bytes32 messageId;
    bytes32 messageHashSum;
    bytes[] allowedOperators;
}

interface IConceroVerifier {}
