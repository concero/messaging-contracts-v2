import { computeNamespace } from "../../utils/computeNamespace";

/**
 * @title Namespaces
 * @notice Contains namespace constants for ConceroRouter.
 */
export const Namespaces = {
	ROUTER: computeNamespace("concerorouter.router.storage"),
	OPERATOR: computeNamespace("concerorouter.operator.storage"),
	PRICEFEED: computeNamespace("concerorouter.pricefeed.storage"),
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

	return Object.freeze({
		nonce: 0,
		isMessageSent: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT,
		isMessageProcessed: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1,
		receivedMessages: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 2,
		messageConfirmationsByProtocol:
			RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 3,
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
	const UINTS_COUNT = 1;

	return Object.freeze({
		totalFeesEarnedNative: 0,
		feesEarnedNative: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT,
	});
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

	return Object.freeze({
		nativeUsdRate: 0,
		lastGasPrices: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT,
		nativeNativeRates: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1,
	});
})();

export { RouterSlots, OperatorSlots, PriceFeedSlots };
