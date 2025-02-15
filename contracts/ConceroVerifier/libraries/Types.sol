// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonTypes} from "../../common/CommonTypes.sol";

library Types {
    enum FeeToken {
        native,
        usdc
    }

    enum ChainType {
        EVM,
        NON_EVM
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
        Deregister, // 0
        Register // 1
    }

    struct MessageReportRequest {
        uint256 internalMessageConfig;
        bytes32 messageId;
        bytes32 messageHashSum;
        bytes srcChainData;
        bytes dstChainData;
    }

    struct OperatorRegistrationResult {
        uint256 reportConfig;
        CommonTypes.ChainType[] operatorChains;
        OperatorRegistrationAction[] operatorActions;
        bytes[] operatorAddresses;
    }
}
