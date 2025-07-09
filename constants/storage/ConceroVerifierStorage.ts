import { computeNamespace } from "../../utils/computeNamespace";

/**
 * @title Namespaces
 * @notice Contains namespace constants for ConceroRouter.
 */
const Namespaces = {
	VERIFIER: computeNamespace("conceroverifier.verifier.storage"),
	OPERATOR: computeNamespace("conceroverifier.operator.storage"),
	CONFIG: computeNamespace("conceroverifier.config.storage"),
};

/**
 * @title VerifierSlots
 * @notice Storage slot definitions for ConceroVerifier contract
 * @dev All slots are calculated using standard Solidity storage layout rules
 */
const VerifierSlots = (() => {
	const _var_gap = 50;
	const _arr_gap = 50;

	return Object.freeze({
		nonce: 0,
		clfRequestStatus: _var_gap + _arr_gap + 1,
		pendingCLFRequests: _var_gap + _arr_gap + 2,
		pendingMessageReports: _var_gap + _arr_gap + 3,
		isChainSupported: _var_gap + _arr_gap + 4,
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
		totalDepositsNative: 1,
		registeredOperators: _var_gap + _arr_gap + 2,
		isRegistered: _var_gap + _arr_gap + 3,
		depositsNative: _var_gap + _arr_gap + 4,
		walletAddress: _var_gap + _arr_gap + 5,
		feesEarnedNative: _var_gap + _arr_gap + 6,
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

export { VerifierSlots, OperatorSlots, ConfigSlots, Namespaces };
