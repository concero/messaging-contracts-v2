// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Message {
    enum MessageConfigErrorType {
        InvalidMinSrcConfirmations, // 0
        InvalidMinDstConfirmations, // 1
        InvalidAdditionalRelayers, // 2
        InvalidFeeToken, // 3
        InvalidConfigVersion, // 4
        InvalidRelayerConfig, // 5
        InvalidSrcChainSelector, // 6
        InvalidDstChainSelector, // 7
        InvalidOperatorLength // 8
    }

    error MessageTooLarge();
    error InvalidClientMessageConfig(MessageConfigErrorType error);
    error InvalidDstChainData();
    error InvalidSrcChainData();
    error InvalidInternalMessageConfig(MessageConfigErrorType error);
}
