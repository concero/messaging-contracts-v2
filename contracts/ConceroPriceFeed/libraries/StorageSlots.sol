// SPDX-License-Identifier: UNLICENSED
/**
 * @title Storage Slots for Concero Protocol Contracts
 * @notice External storage slot definitions for protocol contracts
 * @dev Used to access contract storage slots externally, primarily in tests
 * @author Concero Team
 */

pragma solidity 0.8.28;

/**
 * @title PriceFeedSlots
 * @notice Storage slot definitions for ConceroPriceFeed contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
library PriceFeedSlots {
    uint256 internal constant nativeUsdRate = 0;
    uint256 private constant _var_gap = 50;
    uint256 private constant _arr_gap = 50;

    uint256 internal constant lastGasPrices = _var_gap + _arr_gap + 1;
    uint256 internal constant nativeNativeRates = _var_gap + _arr_gap + 2;
}
