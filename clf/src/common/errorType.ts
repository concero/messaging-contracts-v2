enum ErrorType {
	UNKNOWN_ERROR = 0,
	INVALID_BYTES_ARGS_LENGTH = 1,
	ARRAY_LENGTH_MISMATCH = 2,

	// Configuration Errors
	CONFIG_INVALID_VERSION = 10,
	CONFIG_INVALID_RELAYER_CONFIG = 11,
	CONFIG_INVALID_MIN_SRC_CONFIRMATIONS = 12,
	CONFIG_INVALID_MIN_DST_CONFIRMATIONS = 13,
	CONFIG_INVALID_SRC_CHAIN_SELECTOR = 14,
	CONFIG_INVALID_DST_CHAIN_SELECTOR = 15,
	INVALID_MESSAGE_CONFIG = 16,

	// Chain and RPC Errors
	NO_CHAIN_DATA = 20,
	NO_RPC_DATA = 21,
	NO_RPC_PROVIDERS = 22,
	INVALID_SOURCE_CHAIN = 23,
	INVALID_DESTINATION_CHAIN = 24,
	INVALID_CHAIN = 25,
	INVALID_RPC = 26,

	// Event and Message Errors
	EVENT_NOT_FOUND = 30,
	INVALID_HASHSUM = 31,
	INVALID_MESSAGE_ID = 32,
	INVALID_DATA = 33,
	INVALID_EXTRA_ARGS = 34,
	INVALID_INPUT = 35,
	INVALID_HASH_SUM = 36,
	INVALID_CHAIN_DATA = 37,
	INVALID_CHAIN_TYPE = 38,

	// Token Errors
	INVALID_TOKEN_TYPE = 40,
	INVALID_TOKEN_AMOUNT = 41,

	// Relayer and Operator Errors
	INVALID_RELAYER = 50,
	INVALID_OPERATOR_COUNT = 51,
	NO_REGISTERED_OPERATORS = 52,
	NO_ALLOWED_OPERATORS = 53,
	OPERATOR_SELECTION_FAILED = 54,
	INVALID_COHORTS_COUNT = 55,
	INVALID_OPERATOR_ADDRESS = 56,
	INVALID_ACTION = 57,
	INVALID_OPERATOR_STAKE = 58,

	// Address Errors
	INVALID_RECEIVER = 60,
	INVALID_SENDER = 61,
	INVALID_UINT256 = 62,
	INVALID_ETHEREUM_ADDRESS = 63,
	DECODE_FAILED = 70,
}
export { ErrorType };
