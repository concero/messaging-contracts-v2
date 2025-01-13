import { type Address, type Chain } from "viem";
import { mainnet } from "viem/chains";

const CONCERO_VERIFIER_CONTRACT_ADDRESS = "0x123";
const CONCERO_VERIFIER_CONTRACT_ABI = ["abi"];
const CONFIG = {
    REPORT_VERSION: 1,
    VIEM: {
        RETRY_COUNT: 5,
        RETRY_DELAY: 2000,
    },
};

enum ChainType {
    EVM,
    NON_EVM,
}
enum ReportType {
    UNKNOWN = 0,
    MESSAGE = 1,
    OPERATOR_REGISTRATION = 2,
}
enum ErrorType {
    UNKNOWN_ERROR = 0,
    NO_CHAIN_DATA = 1,
    NO_RPC_DATA = 2,
    EVENT_NOT_FOUND = 3,
    INVALID_HASHSUM = 4,
    INVALID_MESSAGE_ID = 5,
    INVALID_SOURCE_CHAIN = 6,
    INVALID_DESTINATION_CHAIN = 7,
    INVALID_RECEIVER = 8,
    INVALID_SENDER = 9,
    INVALID_TOKEN_TYPE = 10,
    INVALID_TOKEN_AMOUNT = 11,
    INVALID_RELAYER = 12,
    INVALID_DATA = 13,
    INVALID_EXTRA_ARGS = 14,
    INVALID_INPUT = 15,
    CONFIG_INVALID_VERSION = 16,
    CONFIG_INVALID_RELAYER_CONFIG = 17,
    CONFIG_INVALID_MIN_SRC_CONFIRMATIONS = 18,
    CONFIG_INVALID_MIN_DST_CONFIRMATIONS = 19,
    CONFIG_INVALID_SRC_CHAIN_SELECTOR = 20,
    CONFIG_INVALID_DST_CHAIN_SELECTOR = 21,
    INVALID_OPERATOR_COUNT = 22,
    NO_REGISTERED_OPERATORS = 23,
    NO_ALLOWED_OPERATORS = 24,
    OPERATOR_SELECTION_FAILED = 25,
    INVALID_COHORTS_COUNT = 26,
}
const INTERNAL_MESSAGE_REPORT_BIT_OFFSETS = {
    VERSION: 248n, // uint8 (8 bits, highest bits of 256-bit number)
    SRC_CHAIN_SELECTOR: 224n, // uint24 (24 bits)
    DST_CHAIN_SELECTOR: 200n, // uint24 (24 bits)
    MIN_SRC_CONF: 184n, // uint16 (16 bits)
    MIN_DST_CONF: 168n, // uint16 (16 bits)
    RELAYER_CONFIG: 160n, // uint8 (8 bits)
    IS_CALLBACKABLE: 159n,
}; // bool (1 bit)

const BIT_MASKS = {
    UINT24: 0xffffffn, // Mask for uint24 (24 bits)
    UINT16: 0xffffn, // Mask for uint16 (16 bits)
    UINT8: 0xffn, // Mask for uint8 (8 bits)
    BOOL: 0x1n, // Mask for 1 bit (bool)
};
const conceroRouters: Record<number, Address> = {
    "1": "0x123",
};

const viemChains: Record<number, Chain> = {
    "1": mainnet,
};

const ClientMessageRequest = "tuple(uint256 messageConfig, bytes dstChainData, bytes message)";
const ConceroMessageSentEvent = [`event ConceroMessageSent(bytes32 indexed, ${ClientMessageRequest})`];

export {
    ReportType,
    ErrorType,
    ChainType,
    ConceroMessageSentEvent,
    viemChains,
    ClientMessageRequest,
    conceroRouters,
    INTERNAL_MESSAGE_REPORT_BIT_OFFSETS,
    BIT_MASKS,
    CONFIG,
    CONCERO_VERIFIER_CONTRACT_ADDRESS,
    CONCERO_VERIFIER_CONTRACT_ABI,
};
