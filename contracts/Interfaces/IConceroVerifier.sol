// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

enum FeeTokenType {
    native,
    USDC
}
enum ChainType {
    EVM,
    NON_EVM
}

enum CLFReportVersion {
    v0,
    v1
}

enum CLFReportType {
    Message,
    OperatorRegistration,
    OperatorDeregistration
}

enum CLFRequestStatus {
    NotStarted,
    Pending,
    FulFilled
}

struct MessageReportRequest {
    uint256 internalMessageConfig;
    bytes32 messageId;
    bytes32 messageHashSum;
    bytes dstChainData;
    bytes srcChainData;
}

struct MessageReportResult {
    uint8 version;
    CLFReportType reportType;
    address operator;
    bytes32 internalMessageConfig;
    bytes32 messageId;
    bytes32 messageHashSum;
    bytes dstChainData;
    bytes[] allowedOperators;
}

struct OperatorRegistrationResult {
    uint8 version;
    address operator;
    ChainType[] operatorChains;
    bytes[] operatorAddresses;
}

event CLFRequestError(bytes err);
event MessageReport(bytes32 indexed conceroId);
event OperatorRegistered(ChainType chainType, bytes operatorAddress);
event OperatorDeregistered(ChainType chainType, bytes operatorAddress);
event OperatorDeposited(address indexed operator, uint256 amount);
event OperatorFeeWithdrawn(address indexed operator, uint256 amount);
interface IConceroVerifier {}
