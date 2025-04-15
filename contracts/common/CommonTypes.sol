// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Types} from "../ConceroRouter/libraries/Types.sol";

library CommonTypes {
    enum ChainType {
        EVM, //                 0
        NON_EVM //              1
    }

    enum CLFReportType {
        Unknown, //             0
        Message, //             1
        OperatorRegistration // 2
    }

    enum CLFReportVersion {
        V1
    }

    struct ClfReportResult {
        bytes32 reportConfig;
        bytes encodedReportData;
    }

    struct ClfMessageReportDataV1 {
        bytes32 messageId;
        bytes[] allowedOperators;
        bytes encodedMessageData;
    }

    struct MessageDataV1 {
        uint8 version;
        bytes32 messageHashSum;
        bytes sender;
        uint24 srcChainSelector;
        uint24 dstChainSelector;
        Types.EvmDstChainData dstChainData;
    }

    // @dev clfReportResponseConfig is a bitmasked uint256
    struct ClfReportResponseConfig {
        uint8 reportType; //               1 byte, (0-255)
        uint8 version; //                  1 byte, (0-255)
        //                                 10 bytes reserved for future use
        address requester; //              20 bytes
    }
}
