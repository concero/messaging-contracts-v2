// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

interface IConceroClientErrors {
    enum RequiredVariableUnsetType {
        NativeUSDRate
    }

    enum MessageConfigErrorType {
        InvalidMinSrcConfirmations,
        InvalidMinDstConfirmations,
        InvalidAdditionalRelayers,
        InvalidFeeToken,
        InvalidConfigVersion,
        InvalidRelayerConfig,
        InvalidSrcChainSelector,
        InvalidDstChainSelector,
        InvalidOperatorLength
    }

    // conceroSend Errors
    error UnsupportedFeeTokenType();

    // MessageLib (client-facing) errors
    error MessageTooLarge();
    error InvalidClientMessageConfig(MessageConfigErrorType error);
    error InvalidDstChainData();

    //utils lib
    error NotAContract(address target);
    error DelegateCallFailed(bytes response);

    //commonErrors
    error InsufficientFee(uint256 provided, uint256 required);
    error RequiredVariableUnset(RequiredVariableUnsetType variableType);
}
