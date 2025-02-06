// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Types {
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

    enum OperatorRegistrationAction {
        Register,
        Deregister
    }

    struct MessageReportRequest {
        uint256 internalMessageConfig;
        bytes32 messageId;
        bytes32 messageHashSum;
        bytes srcChainData;
        bytes dstChainData;
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
        uint8 reportType;
        address operator;
        ChainType[] operatorChains;
        OperatorRegistrationAction[] operatorActions;
        bytes[] operatorAddresses;
    }
}
