import {parseAbi} from "viem";

export const ClientMessageRequestBase =
	"uint8 version, bool shouldFinaliseSrc, uint24 dstChainSelector, bytes dstChainData, bytes sender, bytes message";
export const ClientMessageRequest = `tuple(${ClientMessageRequestBase})`;
export const CONCERO_VERIFIER_CONTRACT_ABI = parseAbi([
	"function getCohortsCount() external returns (uint8)",
	"function getRegisteredOperators(uint8 chainType) external view returns (bytes[] memory)",
]);

export const NonIndexedConceroMessageParams = [
	{ type: "uint8", name: "version" },
	{ type: "bool", name: "shouldFinaliseSrc" },
	{ type: "uint24", name: "dstChainSelector" },
	{ type: "bytes", name: "dstChainData" },
	{ type: "address", name: "sender" },
	{ type: "bytes", name: "message" },
];

export const ConceroMessageLogParams = [
	{ type: "bytes32", name: "messageId", indexed: true },
	...NonIndexedConceroMessageParams,
];

export const conceroMessageSentEventName = "ConceroMessageSent";

export const ConceroMessageSentEvent = [
	`event ${conceroMessageSentEventName}(bytes32 indexed messageId, uint8 version, bool shouldFinaliseSrc, uint24 dstChainSelector, bytes dstChainData, bytes sender, bytes message)`,
];

export const messageReportResultParams = [
	{
		type: "tuple",
		components: [
			{ type: "bytes32", name: "messageId" },
			{ type: "bytes32", name: "messageHashSum" },
			{ type: "bytes", name: "messageSender" },
			{ type: "uint24", name: "srcChainSelector" },
			{ type: "uint24", name: "dstChainSelector" },
			{ type: "uint256", name: "srcBlockNumber" },
			{
				type: "tuple",
				name: "dstChainData",
				components: [
					{ type: "address", name: "receiver" },
					{ type: "uint256", name: "gasLimit" },
				],
			},
			{ type: "bytes[]", name: "allowedOperators" },
		],
	},
];
