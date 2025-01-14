// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library CommonConstants {
    uint256 internal constant CLF_REPORT_OPERATOR_FEE = 1e18;
    uint256 internal constant MESSAGE_RELAY_OPERATOR_FEE = 1e18;
    uint256 internal constant CONCERO_MESSAGE_FEE = 1e18;
    uint256 internal constant STAKER_FEE = 1e18;
    uint256 internal constant OPERATOR_MESSAGE_REPORT_REQUEST_DEPOSIT = 1e18;
    uint256 internal constant OPERATOR_REGISTRATION_REPORT_REQUEST_DEPOSIT = 1e18; //larger than msg deposit

    uint8 internal constant COHORTS_COUNT = 1;
}
