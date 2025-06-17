import { computeNamespace } from "../../utils/computeNamespace";

/**
 * @title Namespaces
 * @notice Contains namespace constants for ConceroRouter.
 */
const Namespaces = {
	ROUTER: computeNamespace("concerorouter.router.storage"),
	OPERATOR: computeNamespace("concerorouter.operator.storage"),
	PRICEFEED: computeNamespace("concerorouter.pricefeed.storage"),
	CONFIG: computeNamespace("concerorouter.config.storage"),
};

/**
 * @title RouterSlots
 * @notice Storage slot definitions for ConceroRouter contract
 * @dev All slots are calculated using standard Solidity storage layout rules with namespace isolation
 */
const RouterSlots = (() => {
	const _var_gap = 50;
	const _arr_gap = 50;

	return Object.freeze({
		nonce: 0,
		isMessageSent: _var_gap + _arr_gap + 1,
		isMessageProcessed: _var_gap + _arr_gap + 2,
		receivedMessages: _var_gap + _arr_gap + 3,
		messageConfirmationsByProtocol: _var_gap + _arr_gap + 4,
		isChainSupported: _var_gap + _arr_gap + 5,
	});
})();

/**
 * @title OperatorSlots
 * @notice Storage slot definitions for ConceroOperator contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
const OperatorSlots = (() => {
	const _var_gap = 50;
	const _arr_gap = 50;

	return Object.freeze({
		totalFeesEarnedNative: 0,
		feesEarnedNative: _var_gap + _arr_gap + 1,
	});
})();

/**
 * @title PriceFeedSlots
 * @notice Storage slot definitions for ConceroPriceFeed contract
 * @dev All slots are calculated using standard Solidity storage layout rules with namespace isolation
 */
const PriceFeedSlots = (() => {
	const _var_gap = 50;
	const _arr_gap = 50;

	return Object.freeze({
		nativeUsdRate: 0,
		lastGasPrices: _var_gap + _arr_gap + 1,
		nativeNativeRates: _var_gap + _arr_gap + 2,
	});
})();

/**
 * @title ConfigSlots
 * @notice Storage slot definitions for Concero configuration variables
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
const ConfigSlots = (() => {
	const _var_gap = 50;
	const _arr_gap = 50;

	return Object.freeze({
		gasFeeConfig: 0,
	});
})();

export { RouterSlots, OperatorSlots, PriceFeedSlots, ConfigSlots, Namespaces };
