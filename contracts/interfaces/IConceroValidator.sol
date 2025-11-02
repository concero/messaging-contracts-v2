// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

interface IConceroValidator {
    event Deposited(address indexed s_relayer, uint256 amount);
    event DepositWithdrawn(address indexed s_relayer, uint256 amount);

    event ValidatorFeeWithdrawn(address indexed validator, uint256 amount);
}
