export const ClientMessageRequestBase = "bytes32 internalMessageConfig, bytes dstChainData, bytes message";
export const ClientMessageRequest = `tuple(${ClientMessageRequestBase})`;
export const CONCERO_VERIFIER_CONTRACT_ABI = ["abi"];

export const ConceroMessageLogParams = [
    { type: "bytes32", name: "messageId", indexed: true },
    { type: "uint256", name: "internalMessageConfig", indexed: true },
    { type: "bytes", name: "dstChainData" },
    { type: "bytes", name: "message" },
];

export const NonIndexedConceroMessageParams = [
    { type: "bytes", name: "dstChainData" },
    { type: "bytes", name: "message" },
];

export const EvmSrcChainDataParams = [
    { type: "address", name: "sender" },
    { type: "uint256", name: "blockNumber" },
];

export const ConceroMessageSentEvent = [
    `event ConceroMessageSent(bytes32 indexed internalMessageConfig, bytes32 indexed messageId, bytes dstChainData, bytes message)`,
];
