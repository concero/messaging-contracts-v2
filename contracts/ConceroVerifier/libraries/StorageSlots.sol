// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

// @notice This is not part of ConceroVerifier contract but is used to access its storage slots externally, e.g. from Foundry tests

library VerifierSlots {
    bytes32 internal constant NONCE = bytes32(0);
    bytes32 internal constant CLF_REQUEST_STATUS = keccak256("clfRequestStatus");
    bytes32 internal constant PENDING_CLF_REQUESTS = keccak256("pendingCLFRequests");
    bytes32 internal constant PENDING_MESSAGE_REPORTS = keccak256("pendingMessageReports");
}

library OperatorSlots {
    bytes32 internal constant IS_ALLOWED = keccak256("isAllowed");
    bytes32 internal constant DEPOSIT = keccak256("deposit");
    bytes32 internal constant REGISTERED_OPERATORS = keccak256("registeredOperators");
    bytes32 internal constant WALLET_ADDRESS = keccak256("walletAddress");
    bytes32 internal constant FEES_EARNED_NATIVE = keccak256("feesEarnedNative");
    bytes32 internal constant FEES_EARNED_USDC = keccak256("feesEarnedUSDC");
}
