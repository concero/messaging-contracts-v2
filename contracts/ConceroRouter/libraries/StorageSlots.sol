// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library RouterSlots {
    bytes32 internal constant NAMESPACE = keccak256("concero.router.storage");

    bytes32 internal constant NONCE = bytes32(0);
    bytes32 internal constant OPERATOR_FEES_EARNED_USDC = keccak256("operatorFeesEarnedUSDC");
    bytes32 internal constant OPERATOR_FEES_EARNED_NATIVE = keccak256("operatorFeesEarnedNative");
    bytes32 internal constant IS_MESSAGE_PROCESSED = keccak256("isMessageProcessed");
    bytes32 internal constant IS_MESSAGE_SENT = keccak256("isMessageSent");
    bytes32 internal constant RECEIVED_MESSAGES = keccak256("receivedMessages");
    bytes32 internal constant MESSAGE_CONFIRMATIONS_BY_PROTOCOL =
        keccak256("messageConfirmationsByProtocol");
}

library PriceFeedSlots {
    bytes32 internal constant NAMESPACE = keccak256("concero.priceFeed.storage");
    bytes32 internal constant NATIVE_USDC_RATE = bytes32(0);
    bytes32 internal constant LAST_GAS_PRICES = keccak256("lastGasPrices");
    bytes32 internal constant NATIVE_NATIVE_RATES = keccak256("nativeNativeRates");
}
