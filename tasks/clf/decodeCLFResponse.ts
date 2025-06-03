import { AbiParameter, decodeAbiParameters } from "viem";

/**
 * Type definitions matching the Solidity contract structures
 */
export interface ClfDonReportSubmission {
	context: string[];
	report: string;
	rs: string[];
	ss: string[];
	rawVs: string;
}

export interface ClfReport {
	requestIds: string[];
	results: string[];
	errors: string[];
	onchainMetadata: string[];
	offchainMetadata: string[];
}

export interface ResultConfig {
	resultType: number;
	payloadVersion: number;
	requester: string;
}

export interface MessagePayloadV1 {
	messageId: string;
	messageHashSum: string;
	messageSender: string;
	srcChainSelector: number;
	dstChainSelector: number;
	srcBlockNumber: bigint;
	dstChainData: {
		receiver: string;
		gasLimit: bigint;
	};
	allowedOperators: string[];
}

export interface MessageResult extends ResultConfig {
	payload: MessagePayloadV1;
}

// Decoder ABI definitions
const clfDonReportSubmissionDecoder: AbiParameter[] = [
	{
		type: "tuple",
		components: [
			{ name: "context", type: "bytes32[3]" },
			{ name: "report", type: "bytes" },
			{ name: "rs", type: "bytes32[]" },
			{ name: "ss", type: "bytes32[]" },
			{ name: "rawVs", type: "bytes32" },
		],
	},
];

const clfReportDecoder: AbiParameter[] = [
	{
		type: "tuple",
		components: [
			{ type: "bytes32[]", name: "requestIds" },
			{ type: "bytes[]", name: "results" },
			{ type: "bytes[]", name: "errors" },
			{ type: "bytes[]", name: "onchainMetadata" },
			{ type: "bytes[]", name: "offchainMetadata" },
		],
	},
];

const resultDecoder: AbiParameter[] = [
	{
		type: "tuple",
		name: "resultConfig",
		components: [
			{ type: "uint8", name: "resultType" },
			{ type: "uint8", name: "payloadVersion" },
			{ type: "address", name: "requester" },
		],
	},
	{ type: "bytes", name: "payload" },
];

const messageReportPayloadDecoder: AbiParameter[] = [
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

/**
 * Decodes a CLF DON Report Submission
 * @param bytes - The encoded CLF DON Report Submission
 * @returns The decoded report submission
 */
export function decodeCLFReportSubmission(bytes: string): ClfDonReportSubmission | null {
	try {
		const responseHex = bytes.startsWith("0x") ? bytes : "0x" + bytes;
		const decoded = decodeAbiParameters(clfDonReportSubmissionDecoder, responseHex);
		return decoded[0] as unknown as ClfDonReportSubmission;
	} catch (error) {
		console.error("Failed to decode CLF DON Report Submission:", error);
		return null;
	}
}

/**
 * Decodes a CLF Report
 * @param bytes - The encoded CLF Report
 * @returns The decoded CLF Report
 */
export function decodeCLFReport(bytes: string): ClfReport | null {
	try {
		const responseHex = bytes.startsWith("0x") ? bytes : "0x" + bytes;
		const decoded = decodeAbiParameters(clfReportDecoder, responseHex);
		return decoded[0] as unknown as ClfReport;
	} catch (error) {
		console.error("Failed to decode CLF Report:", error);
		return null;
	}
}

/**
 * Decodes a message result from a CLF result byte array
 * @param resultBytes - The encoded result bytes
 * @returns The decoded result object
 */
export function decodeMessageResult(resultBytes: string): MessageResult | null {
	try {
		// Ensure hex format
		const responseHex = resultBytes.startsWith("0x") ? resultBytes : "0x" + resultBytes;

		// Decode the result (ResultConfig, bytes)
		const decodedResult = decodeAbiParameters(resultDecoder, responseHex);

		// Extract result config and payload
		const resultConfig = decodedResult[0] as ResultConfig;
		const payloadBytes = decodedResult[1] as string;

		// For message reports (result type 1), decode the payload
		if (resultConfig.resultType === 1) {
			try {
				const decodedPayloadArray = decodeAbiParameters(messageReportPayloadDecoder, payloadBytes);
				const payloadData = decodedPayloadArray[0] as any;

				// Decode messageSender which is encoded as bytes but represents an address
				let messageSender = payloadData.messageSender;
				if (messageSender) {
					try {
						messageSender = decodeAbiParameters([{ type: "address" }], messageSender)[0];
					} catch (error) {
						console.warn("Failed to decode messageSender as address:", error);
					}
				}

				// Create full message result
				return {
					...resultConfig,
					payload: {
						messageId: payloadData.messageId,
						messageHashSum: payloadData.messageHashSum,
						messageSender: messageSender,
						srcChainSelector: payloadData.srcChainSelector,
						dstChainSelector: payloadData.dstChainSelector,
						srcBlockNumber: payloadData.srcBlockNumber,
						dstChainData: payloadData.dstChainData,
						allowedOperators: payloadData.allowedOperators,
					},
				};
			} catch (payloadError) {
				console.error("Failed to decode message payload:", payloadError);
				return null;
			}
		}

		return null;
	} catch (error) {
		console.error("Failed to decode message result:", error);
		return null;
	}
}

/**
 * Helper function to process a CLF report submission and extract message result
 * @param reportSubmission - The CLF DON report submission or bytes
 * @returns The decoded message result
 */
export function extractMessageResult(reportSubmission: ClfDonReportSubmission | string): MessageResult | null {
	try {
		// Handle either direct bytes or submission object
		const report = typeof reportSubmission === 'string'
			? reportSubmission
			: reportSubmission.report;

		// Decode the report
		const clfReport = decodeCLFReport(report);
		if (!clfReport || !clfReport.results || clfReport.results.length === 0) {
			console.error("No results found in CLF report");
			return null;
		}

		// Take the first result (typically there's only one)
		return decodeMessageResult(clfReport.results[0]);
	} catch (error) {
		console.error("Failed to extract message result:", error);
		return null;
	}
}
