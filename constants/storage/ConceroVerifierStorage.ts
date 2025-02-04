import { computeNamespace } from "../../utils/computeNamespace";

/**
 * @title Namespaces
 * @notice Contains namespace constants for ConceroRouter.
 */
export const Namespaces = {
    VERIFIER: computeNamespace("conceroverifier.verifier.storage"),
    OPERATOR: computeNamespace("conceroverifier.operator.storage"),
    PRICEFEED: computeNamespace("conceroverifier.pricefeed.storage"),
};

/**
 * @title VerifierSlots
 * @notice Storage slot definitions for ConceroVerifier contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
const VerifierSlots = (() => {
    const RESERVED_VARIABLE_GAP = 50;
    const RESERVED_ARRAY_GAP = 50;
    const UINTS_COUNT = 1;

    const nonce = 0;
    const clfRequestStatus = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0;
    const pendingCLFRequests = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1;
    const pendingMessageReports = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 2;

    return Object.freeze({
        nonce,
        clfRequestStatus,
        pendingCLFRequests,
        pendingMessageReports,
    });
})();

/**
 * @title OperatorSlots
 * @notice Storage slot definitions for ConceroOperator contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
const OperatorSlots = (() => {
    const RESERVED_VARIABLE_GAP = 50;
    const RESERVED_ARRAY_GAP = 50;
    const UINTS_COUNT = 2;

    const totalFeesEarnedNative = 0;
    const totalDepositsNative = 1;
    const registeredOperators = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0;
    const isAllowed = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1;
    const depositsNative = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 2;
    const walletAddress = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 3;
    const feesEarnedNative = RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 4;

    return Object.freeze({
        totalFeesEarnedNative,
        totalDepositsNative,
        registeredOperators,
        isAllowed,
        depositsNative,
        walletAddress,
        feesEarnedNative,
    });
})();

/**
 * @title PriceFeedSlots
 * @notice Storage slot definitions for ConceroPriceFeed contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
const PriceFeedSlots = (() => {
    const RESERVED_VARIABLE_GAP = 50;
    const UINTS_COUNT = 1;

    const nativeUsdRate = 0;
    const lastGasPrices = RESERVED_VARIABLE_GAP + UINTS_COUNT + 0;
    const nativeNativeRates = RESERVED_VARIABLE_GAP + UINTS_COUNT + 1;

    return Object.freeze({
        nativeUsdRate,
        lastGasPrices,
        nativeNativeRates,
    });
})();

export { VerifierSlots, OperatorSlots, PriceFeedSlots };
