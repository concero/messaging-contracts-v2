// SPDX-License-Identifier: UNLICENSED
/**
 * @title Storage Slots for Concero Protocol Contracts
 * @notice External storage slot definitions for protocol contracts
 * @dev Used to access contract storage slots externally, primarily in tests
 * @author Concero Team
 */
pragma solidity 0.8.28;

/**
 * @title RouterSlots
 * @notice Storage slot definitions for ConceroRouter contract
 * @dev All slots are calculated using standard Solidity storage layout rules with namespace isolation
 */
library RouterSlots {
    uint256 private constant RESERVED_VARIABLE_GAP = 50;
    uint256 private constant RESERVED_ARRAY_GAP = 50;
    uint256 private constant UINTS_COUNT = 1;

    uint256 internal constant nonce = 0;

    uint256 internal constant isMessageSent =
        RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0;
    uint256 internal constant isMessageProcessed =
        RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1;
    uint256 internal constant receivedMessages =
        RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 2;
    uint256 internal constant messageConfirmationsByProtocol =
        RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 3;
}

/**
 * @title PriceFeedSlots
 * @notice Storage slot definitions for ConceroPriceFeed contract
 * @dev All slots are calculated using standard Solidity storage layout rules with namespace isolation
 */
library PriceFeedSlots {
    uint256 private constant RESERVED_VARIABLE_GAP = 50;
    uint256 private constant RESERVED_ARRAY_GAP = 50;
    uint256 private constant UINTS_COUNT = 1;

    uint256 internal constant nativeUsdRate = 0;

    uint256 internal constant lastGasPrices =
        RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0;
    uint256 internal constant nativeNativeRates =
        RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1;
}

/**
 * @title OperatorSlots
 * @notice Storage slot definitions for ConceroOperator contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
library OperatorSlots {
    uint256 private constant RESERVED_VARIABLE_GAP = 50;
    uint256 private constant RESERVED_ARRAY_GAP = 50;
    uint256 private constant UINTS_COUNT = 1;

    uint256 internal constant totalFeesEarnedNative = 0;

    uint256 internal constant feesEarnedNative =
        RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0;
}
