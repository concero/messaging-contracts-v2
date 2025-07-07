// SPDX-License-Identifier: UNLICENSED
/**
 * @title Storage Slots for Concero Protocol Contracts
 * @notice External storage slot definitions for protocol contracts
 * @dev Used to access contract storage slots externally, primarily in tests
 * @author Concero Team
 */

pragma solidity 0.8.28;

/**
 * @title VerifierSlots
 * @notice Storage slot definitions for ConceroVerifier contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
library VerifierSlots {
    uint256 internal constant nonce = 0;
    uint256 private constant _var_gap = 50;
    uint256 private constant _arr_gap = 50;

    uint256 internal constant clfRequestStatus = _var_gap + _arr_gap + 1;
    uint256 internal constant pendingCLFRequests = _var_gap + _arr_gap + 2;
    uint256 internal constant pendingMessageReports = _var_gap + _arr_gap + 3;
    uint256 internal constant isChainSupported = _var_gap + _arr_gap + 4;
}

/**
 * @title OperatorSlots
 * @notice Storage slot definitions for ConceroOperator contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
library OperatorSlots {
    uint256 internal constant totalFeesEarnedNative = 0;
    uint256 internal constant totalDepositsNative = 1;
    uint256 private constant _var_gap = 50;
    uint256 private constant _arr_gap = 50;

    uint256 internal constant registeredOperators = _var_gap + _arr_gap + 2;
    uint256 internal constant isRegistered = _var_gap + _arr_gap + 3;
    uint256 internal constant depositsNative = _var_gap + _arr_gap + 4;
    uint256 internal constant walletAddress = _var_gap + _arr_gap + 5;
    uint256 internal constant feesEarnedNative = _var_gap + _arr_gap + 6;
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
