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
	const RESERVED_ARRAY_GAP = 49;
	const UINTS_COUNT = 1;
	const ARRAYS_COUNT = 1;

	return Object.freeze({
		nonce: 0,
		supportedChainSelectors: UINTS_COUNT + RESERVED_VARIABLE_GAP,
		clfRequestStatus:
			RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + ARRAYS_COUNT + 0,
		pendingCLFRequests:
			RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + ARRAYS_COUNT + 1,
		pendingMessageReports:
			RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + ARRAYS_COUNT + 2,
		isChainSupported:
			RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + ARRAYS_COUNT + 3,
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

	return Object.freeze({
		totalFeesEarnedNative: 0,
		totalDepositsNative: 1,
		registeredOperators: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT,
		isRegistered: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 1,
		depositsNative: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 2,
		walletAddress: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 3,
		feesEarnedNative: RESERVED_VARIABLE_GAP + RESERVED_ARRAY_GAP + UINTS_COUNT + 4,
	});
})();

/**
 * @title PriceFeedSlots
 * @notice Storage slot definitions for ConceroPriceFeed contract
 * @dev All slots are calculated using standard Solidity storage layout rules
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

export { VerifierSlots, OperatorSlots, PriceFeedSlots };
