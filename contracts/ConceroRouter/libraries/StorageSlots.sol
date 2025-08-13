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
    uint256 internal constant messageStatus = _var_gap + _arr_gap + 3;
    uint256 internal constant retryableMessages = _var_gap + _arr_gap + 4;
    uint256 internal constant isChainSupported = _var_gap + _arr_gap + 5;
    uint256 internal constant processedTxHashes = _var_gap + _arr_gap + 6;
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
