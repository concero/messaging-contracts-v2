enum ErrorType {
    // General Errors
    UNKNOWN_ERROR = 0,

    // Configuration Errors
    CONFIG_INVALID_VERSION = 10,

    // Chain and RPC Errors
    INVALID_CHAIN_TYPE = 20,
    INVALID_OPERATOR_ADDRESS = 21,

    // Operator Errors
    INVALID_OPERATOR_STAKE = 30,
    INVALID_OPERATOR_COUNT = 31,

    // Input Errors
    INVALID_INPUT = 40,
}

export { ErrorType };
