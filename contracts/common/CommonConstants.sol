// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library CommonConstants {
    uint16 internal constant BPS_DENOMINATOR = 10000;
    uint16 internal constant CLF_PREMIUM_FEE_BPS_USD = 300;

    /* Message */

    uint256 internal constant MESSAGE_MAX_SIZE = 1e6; // 1 MB
}
