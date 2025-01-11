import { type Address, type Chain } from "viem";
import { mainnet } from "viem/chains";
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
}

const conceroRouters: Record<number, Address> = {
    "1": "0x123",
};

const viemChains: Record<number, Chain> = {
    "1": mainnet,
};

const ClientMessageRequest = "tuple(uint256 messageConfig, bytes dstChainData, bytes message)";
const ConceroMessageSentEvent = [`event ConceroMessageSent(bytes32 indexed, ${ClientMessageRequest})`];

export { ErrorType, ConceroMessageSentEvent, viemChains, ClientMessageRequest, conceroRouters };
