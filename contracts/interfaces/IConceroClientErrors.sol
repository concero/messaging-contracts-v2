// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

interface IConceroClientErrors {
    enum RequiredVariableUnsetType {
        NativeUSDRate, //                0
        lastGasPrice //                  1
    }

    enum MessageConfigErrorType {
        InvalidMinSrcConfirmations, //   0
        InvalidMinDstConfirmations, //   1
        InvalidAdditionalRelayers, //    2
        InvalidFeeToken, //              3
        InvalidConfigVersion, //         4
        InvalidRelayerConfig, //         5
        InvalidSrcChainSelector, //      6
        InvalidDstChainSelector, //      7
        InvalidOperatorLength //         8
    }

    // conceroSend Errors
    error UnsupportedFeeTokenType();

    // MessageLib (client-facing) errors
    error MessageTooLarge();
    error InvalidClientMessageConfig(MessageConfigErrorType error);
    error InvalidDstChainData();

    //utils lib
    //todo: check all errors if they need to be here.
    error NotAContract(address target);
    error DelegateCallFailed(bytes response);

    //commonErrors
    error InsufficientFee(uint256 provided, uint256 required);
    error RequiredVariableUnset(RequiredVariableUnsetType variableType);
}
