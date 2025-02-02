import { computeNamespace } from "../../utils/computeNamespace";

/**
 * @title Namespaces
 * @notice Contains namespace constants for ConceroRouter.
 */
export const Namespaces = {
    ROUTER: computeNamespace("ConceroRouter.router.storage"),
    OPERATOR: computeNamespace("ConceroRouter.operator.storage"),
    PRICEFEED: computeNamespace("ConceroRouter.priceFeed.storage"),
};

/**
 * @title RouterSlots
 * @notice Storage slot definitions for ConceroRouter contract
 * @dev All slots are calculated using standard Solidity storage layout rules with namespace isolation
 */
const RouterSlots = (() => {
    const RESERVED_VARIABLE_GAP = 50;
    const RESERVED_ARRAY_GAP = 50;
    const UINTS_COUNT = 1;
    return {
        nonce: 0,
        isMessageSent: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0,
        isMessageProcessed: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1,
        receivedMessages: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 2,
        messageConfirmationsByProtocol: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 3,
    };
})();

/**
 * @title PriceFeedSlots
 * @notice Storage slot definitions for ConceroPriceFeed contract
 * @dev All slots are calculated using standard Solidity storage layout rules with namespace isolation
 */
const PriceFeedSlots = (() => {
    const RESERVED_VARIABLE_GAP = 50;
    const RESERVED_ARRAY_GAP = 50;
    const UINTS_COUNT = 1;
    return {
        nativeUsdRate: 0,
        lastGasPrices: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0,
        nativeNativeRates: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1,
    };
})();

/**
 * @title OperatorSlots
 * @notice Storage slot definitions for ConceroOperator contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
const OperatorSlots = (() => {
    const RESERVED_VARIABLE_GAP = 50;
    const RESERVED_ARRAY_GAP = 50;
    const UINTS_COUNT = 1;
    return {
        totalFeesEarnedNative: 0,
        feesEarnedNative: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 0,
    };
})();

export { RouterSlots, PriceFeedSlots, OperatorSlots };
