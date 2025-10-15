// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library ConceroTypes {
    struct EvmDstChainData {
        address receiver;
        uint256 gasLimit;
    }

    struct MessageRequest {
        bytes sender;
        uint24 srcChainSelector;
        uint24 dstChainSelector;
        EvmDstChainData dstChainData;
        bytes[] validatorsConfig;
        bytes relayerConfig;
        bytes payload;
    }

    struct MessageHeader {
        uint64 srcBlockConfirmations;
        address[] validatorsLibs;
        address relayerLib;
        bytes[] validationRPCs;
        bytes[] deliveryRPCs;
        address feeToken;
    }
}
