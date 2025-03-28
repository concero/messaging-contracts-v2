// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library CommonTypes {
    enum FeeToken {
        native,
        usdc
    }

    enum ChainType {
        EVM,
        NON_EVM
    }

    enum CLFReportType {
        Unknown, // 0
        Message, // 1
        OperatorRegistration // 2
    }

    struct MessageReportResult {
        bytes32 reportConfig;
        bytes32 internalMessageConfig;
        bytes32 messageId;
        bytes32 messageHashSum;
        bytes sender;
        bytes dstChainData;
        bytes[] allowedOperators;
    }

    // @dev clfReportResponseConfig is a bitmasked uint256
    struct ClfReportResponseConfig {
        uint8 reportType; //               1 byte, (0-255)
        uint8 version; //                  1 byte, (0-255)
        //                                 10 bytes reserved for future use
        address requester; //              20 bytes
    }
}
