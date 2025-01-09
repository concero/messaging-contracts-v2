// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

contract ConceroRouterStorage {
    uint256 public s_nonce;

    mapping(address => bool) internal s_isAllowedOperator;
    mapping(address => uint256) internal s_operatorFeesEarnedUSDC;
    mapping(bytes32 messageId => bool isProcessed) internal s_isMessageProcessed;
}
