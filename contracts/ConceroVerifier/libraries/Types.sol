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
    enum ChainType {
        EVM, //                   0
        NON_EVM //                1
    }

    enum CLFRequestStatus {
        NotStarted, //            0
        Pending, //               1
        FulFilled //              2
    }

    enum OperatorRegistrationAction {
        Deregister, //            0
        Register //               1
    }

    struct OperatorRegistrationResult {
        CommonTypes.ChainType[] operatorChains;
        OperatorRegistrationAction[] operatorActions;
        bytes[] operatorAddresses;
    }
}
