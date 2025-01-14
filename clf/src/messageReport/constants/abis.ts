const ClientMessageRequest = "tuple(uint256 messageConfig, bytes dstChainData, bytes message)";
const ConceroMessageSentEvent = [`event ConceroMessageSent(bytes32 indexed, ${ClientMessageRequest})`];
const CONCERO_VERIFIER_CONTRACT_ABI = ["abi"];

export { ClientMessageRequest, ConceroMessageSentEvent, CONCERO_VERIFIER_CONTRACT_ABI };
