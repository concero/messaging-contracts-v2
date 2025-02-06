// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library ConceroTypes {
    enum FeeToken {
        native,
        usdc
    }

    struct EvmDstChainData {
        address receiver;
        uint256 gasLimit;
    }

    struct ClientMessageConfig {
        uint24 dstChainSelector;
        uint8 minSrcConfirmations;
        uint8 minDstConfirmations;
        uint8 relayerConfig;
        bool isCallbackable;
        FeeToken feeToken;
    }
}
