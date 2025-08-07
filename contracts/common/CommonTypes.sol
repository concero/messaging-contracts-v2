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

    enum ResultType {
        Unknown, //             0
        Message, //             1
        OperatorRegistration // 2
    }

    struct ResultConfig {
        ResultType resultType;
        uint8 payloadVersion;
        address requester;
    }

    struct MessagePayloadV1 {
        bytes32 messageId;
        bytes32 messageHashSum;
        bytes messageSender;
        uint24 srcChainSelector;
        uint24 dstChainSelector;
        uint256 srcBlockNumber;
        Types.EvmDstChainData dstChainData;
        bytes[] allowedOperators;
    }

    // VerifierResult = abi.encode(ResultConfig resultConfig, bytes payload);
}
