// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonTypes} from "../../common/CommonTypes.sol";

struct CLFParams {
        address router;
        bytes32 donId;
        uint64 subscriptionId;
        uint64 donHostedSecretsVersion;
        uint8 donHostedSecretsSlotId;
        uint16 premiumFeeUsdBps;
        uint32 callbackGasLimit;
        bytes32 requestCLFMessageReportJsCodeHash;
        bytes32 requestOperatorRegistrationJsCodeHash;
    }
    
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
        OperatorRegistration
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
        bytes32 internalMessageConfig;
        bytes32 messageId;
        bytes32 messageHashSum;
        bytes srcChainData;
        bytes dstChainData;
    }

    struct OperatorRegistrationResult {
        bytes32 reportConfig;
        CommonTypes.ChainType[] operatorChains;
        OperatorRegistrationAction[] operatorActions;
        bytes[] operatorAddresses;
    }
}
