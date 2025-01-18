// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Errors {
    error MessageAlreadyProcessed();
    error InvalidEVMAddress();
    error InsufficientOperatorDeposit();
    error UnauthorizedOperator();
    error OperatorNotFound();
    error OperatorAlreadyRegistered();
    error OperatorNotRegistered();
    error OperatorAddressMismatch();
}
