// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library CommonConstants {
    uint8 internal constant USDC_DECIMALS = 6;
    uint16 internal constant BPS_DENOMINATOR = 10000;
    uint8 internal constant COHORTS_COUNT = 1;
    uint16 internal constant CONCERO_MESSAGE_BASE_FEE_BPS_USD = 100;
    uint16 internal constant CLF_PREMIUM_FEE_BPS_USD = 300;
    uint256 internal constant STAKER_FEE = 1e18;
    uint256 internal constant DECIMALS = 1e18;

    /* Operator fees & deposits */
    uint16 internal constant OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD = 100;
    uint16 internal constant OPERATOR_FEE_MESSAGE_RELAY_BPS_USD = 100;
    uint16 internal constant OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD = 100;
    uint16 internal constant OPERATOR_DEPOSIT_REGISTRATION_REPORT_REQUEST_BPS_USD = 200;
    uint256 internal constant OPERATOR_DEPOSIT_MINIMUM_NATIVE = 1_000_000 wei; // 0.001 ETH

    uint256 internal constant MESSAGE_BASE_FEE_USD = 1e18 / 100; // 0.01 USD
    uint256 internal constant MESSAGE_MAX_SIZE = 1e6; // 1 MB
}
