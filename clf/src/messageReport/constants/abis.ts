const ClientMessageRequest = "tuple(bytes32 internalMessageConfig, bytes dstChainData, bytes message)";
const CONCERO_VERIFIER_CONTRACT_ABI = ["abi"];

const ConceroMessageLogParams = [
    { type: "bytes32", name: "messageId", indexed: true },
    { type: "uint256", name: "internalMessageConfig", indexed: true },
    { type: "bytes", name: "dstChainData" },
    { type: "bytes", name: "message" },
];

const NonIndexedConceroMessageParams = [
    { type: "bytes", name: "dstChainData" },
    { type: "bytes", name: "message" },
];

const EvmSrcChainDataParams = [
    { type: "address", name: "sender" },
    { type: "uint256", name: "blockNumber" },
];

const ConceroMessageSentEvent = [
    `event ConceroMessageSent(bytes32 indexed internalMessageConfig, bytes32 indexed messageId, bytes dstChainData, bytes message)`,
];

export {
    ConceroMessageLogParams,
    NonIndexedConceroMessageParams,
    EvmSrcChainDataParams,
    ConceroMessageSentEvent,
    CONCERO_VERIFIER_CONTRACT_ABI,
    ClientMessageRequest,
};
