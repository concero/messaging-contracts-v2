// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

enum Protocol {
    ProtocolA,
    ProtocolB,
    ProtocolC,
    ProtocolD,
    ProtocolE,
    ProtocolF,
    ProtocolG,
    ProtocolH,
    ProtocolI,
    ProtocolJ
}

enum CLFRequestStatus {
    NotStarted,
    Pending,
    FulFilled
}

interface ICLFRouter {}
