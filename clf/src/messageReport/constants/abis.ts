import { parseAbi } from "viem";

export const ClientMessageRequestBase =
	"uint8 version, bool shouldFinaliseSrc, uint24 dstChainSelector, bytes dstChainData, bytes sender, bytes message";
export const ClientMessageRequest = `tuple(${ClientMessageRequestBase})`;
export const CONCERO_VERIFIER_CONTRACT_ABI = parseAbi([
	"function getCohortsCount() external returns (uint8)",
	"function getRegisteredOperators(uint8 chainType) external view returns (bytes[] memory)",
]);

export const ConceroMessageLogParams = [
	{ type: "bytes32", name: "messageId", indexed: true },
	{ type: "uint8", name: "version" },
	{ type: "bool", name: "shouldFinaliseSrc" },
	{ type: "uint24", name: "dstChainSelector" },
	{ type: "bytes", name: "dstChainData" },
	{ type: "bytes", name: "sender" },
	{ type: "bytes", name: "message" },
];

export const NonIndexedConceroMessageParams = [
	{ type: "uint8", name: "version" },
	{ type: "bool", name: "shouldFinaliseSrc" },
	{ type: "uint24", name: "dstChainSelector" },
	{ type: "bytes", name: "dstChainData" },
	{ type: "bytes", name: "sender" },
	{ type: "bytes", name: "message" },
];

export const EvmSrcChainDataParams = [
	{ type: "address", name: "sender" },
	{ type: "uint256", name: "blockNumber" },
];

export const ConceroMessageSentEvent = [
	`event ConceroMessageSent(bytes32 indexed messageId, uint8 version, bool shouldFinaliseSrc, uint24 dstChainSelector, bytes dstChainData, bytes sender, bytes message)`,
];
