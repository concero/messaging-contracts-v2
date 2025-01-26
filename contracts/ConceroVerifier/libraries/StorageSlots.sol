// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

// @notice This is not part of ConceroVerifier contract but is used to access its storage slots externally, e.g. from Foundry tests

library VerifierSlots {
    uint256 internal constant nonce = 0;
    uint256 internal constant __VAR_GAP = 50;
    uint256 internal constant __ARRAY_GAP = 50;
    uint256 internal constant clfRequestStatus = __VAR_GAP + __ARRAY_GAP + 1;
    uint256 internal constant pendingCLFRequests = __VAR_GAP + __ARRAY_GAP + 2;
    uint256 internal constant pendingMessageReports = __VAR_GAP + __ARRAY_GAP + 3;
}

library OperatorSlots {
    uint256 internal constant __VAR_GAP = 50;
    uint256 internal constant __ARRAY_GAP = 50;
    uint256 internal constant isAllowed = __VAR_GAP + __ARRAY_GAP + 1;
    uint256 internal constant deposit = __VAR_GAP + __ARRAY_GAP + 2;
    uint256 internal constant registeredOperators = __VAR_GAP + __ARRAY_GAP + 3;
    uint256 internal constant walletAddress = __VAR_GAP + __ARRAY_GAP + 4;
    uint256 internal constant feesEarnedNative = __VAR_GAP + __ARRAY_GAP + 5;
    uint256 internal constant feesEarnedUSDC = __VAR_GAP + __ARRAY_GAP + 6;
}
