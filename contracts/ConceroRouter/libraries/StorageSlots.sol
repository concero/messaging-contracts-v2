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
    uint256 internal constant nonce = 0;
    uint256 private constant _var_gap = 50;
    uint256 private constant _arr_gap = 50;

    uint256 internal constant isMessageSent = _var_gap + _arr_gap + 1;
    uint256 internal constant isMessageProcessed = _var_gap + _arr_gap + 2;
    uint256 internal constant receivedMessages = _var_gap + _arr_gap + 3;
    uint256 internal constant messageConfirmationsByProtocol = _var_gap + _arr_gap + 4;
    uint256 internal constant isChainSupported = _var_gap + _arr_gap + 5;
}

/**
 * @title PriceFeedSlots
 * @notice Storage slot definitions for ConceroPriceFeed contract
 * @dev All slots are calculated using standard Solidity storage layout rules with namespace isolation
 */
library PriceFeedSlots {
    uint256 internal constant nativeUsdRate = 0;
    uint256 private constant _var_gap = 50;
    uint256 private constant _arr_gap = 50;

    uint256 internal constant lastGasPrices = _var_gap + _arr_gap + 1;
    uint256 internal constant nativeNativeRates = _var_gap + _arr_gap + 2;
}
/**
 * @title OperatorSlots
 * @notice Storage slot definitions for ConceroOperator contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
library OperatorSlots {
    uint256 internal constant totalFeesEarnedNative = 0;
    uint256 private constant _var_gap = 50;
    uint256 private constant _arr_gap = 50;

    uint256 internal constant feesEarnedNative = _var_gap + _arr_gap + 1;
}

/**
 * @title ConfigSlots
 * @notice Storage slot definitions for Concero configuration variables
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
library ConfigSlots {
    uint256 internal constant gasFeeConfig = 0;
    uint256 private constant _var_gap = 50;
    uint256 private constant _arr_gap = 50;
}
