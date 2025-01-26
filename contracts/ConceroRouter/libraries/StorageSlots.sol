// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library RouterSlots {
    bytes32 internal constant NAMESPACE = keccak256("concero.router.storage");

    uint256 internal constant nonce = 0;
    uint256 internal constant __VAR_GAP = 50;
    uint256 internal constant __ARRAY_GAP = 50;

    uint256 internal constant isMessageSent = __VAR_GAP + __ARRAY_GAP + 1;
    uint256 internal constant operatorFeesEarnedUSDC = __VAR_GAP + __ARRAY_GAP + 2;
    uint256 internal constant operatorFeesEarnedNative = __VAR_GAP + __ARRAY_GAP + 3;
    uint256 internal constant isMessageProcessed = __VAR_GAP + __ARRAY_GAP + 4;
    uint256 internal constant receivedMessages = __VAR_GAP + __ARRAY_GAP + 5;
    uint256 internal constant messageConfirmationsByProtocol = __VAR_GAP + __ARRAY_GAP + 6;
}

library PriceFeedSlots {
    bytes32 internal constant NAMESPACE = keccak256("concero.priceFeed.storage");

    uint256 internal constant nativeUsdcRate = 0;
    uint256 internal constant __VAR_GAP = 50;
    uint256 internal constant __ARRAY_GAP = 50;
    uint256 internal constant lastGasPrices = __VAR_GAP + __ARRAY_GAP + 1;
    uint256 internal constant nativeNativeRates = __VAR_GAP + __ARRAY_GAP + 2;
}
