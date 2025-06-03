import {
	Address,
	Hash,
	decodeAbiParameters,
	decodeEventLog,
	encodeAbiParameters,
	keccak256,
} from "viem";

import { globalConfig } from "@concero/v2-operators/src/constants";

import { getEnvVar } from "../../../utils";
import { ExtendedTestClient } from "../../../utils/getViemClients";
import { getCLFReport } from "../getCLFReport";
import { getMessageCLFReportResponse } from "../getMessageCLFReportResponse";

export function createDstChainData(reciever: Address, gasLimit: bigint): string {
	const dstChainData = encodeAbiParameters(
		[{ type: "address" }, { type: "uint256" }],
		[reciever, gasLimit],
	);

	return dstChainData;
}

function createSrcChainData(sender: Address, blockNumber: number) {
	return encodeAbiParameters(
		[
			{
				type: "tuple",
				components: [
					{ type: "uint256", name: "blockNumber" },
					{ type: "address", name: "sender" },
				],
			},
		],
		[{ sender, blockNumber: BigInt(blockNumber) }],
	);
}

export async function handleMessageReportRequest(
	testClient: ExtendedTestClient,
	txHash: Hash,
	mockCLFRouter: Address,
	conceroVerifier: Address,
	conceroClientExample: Address,
) {
	const { abi: mockCLFRouterAbi } = await import(
		"../../../artifacts/contracts/mocks/MockCLFRouter.sol/MockCLFRouter.json"
	);
	const { abi: conceroVerifierAbi } = await import(
		"../../../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const receipt = await testClient.getTransactionReceipt({ hash: txHash });

	let messageReportLog;
	let requestSentLog;

	for (const log of receipt.logs) {
		try {
			const decoded = decodeEventLog({
				abi: globalConfig.ABI.CONCERO_VERIFIER,
				data: log.data,
				topics: log.topics,
				strict: true,
			});

			if (decoded.eventName === "MessageReportRequested") {
				messageReportLog = { log, decoded };
			} else if (decoded.eventName === "RequestSent") {
				requestSentLog = { log, decoded };
			}
		} catch {}
	}

	if (!messageReportLog) throw new Error("MessageReportRequested event not found");

	if (!requestSentLog) throw new Error("RequestSent event not found");

	const latestBlockNumber = await testClient.getBlockNumber();
	const logs = await testClient.getLogs({
		fromBlock: BigInt(Math.max(0, Number(latestBlockNumber - 10000n))),
		toBlock: latestBlockNumber,
	});

	let messageLog;
	let messageLogBlockNumber;
	for (const log of logs) {
		try {
			const decoded = decodeEventLog({
				abi: globalConfig.ABI.CONCERO_ROUTER,
				data: log.data,
				topics: log.topics,
			});

			if (
				decoded.eventName === "ConceroMessageSent" &&
				decoded.args.messageId.toLowerCase() ===
					messageReportLog.log.topics[1]?.toLocaleLowerCase()
			) {
				messageLog = decoded;
				messageLogBlockNumber = log.blockNumber;
				break;
			}
		} catch {
			continue;
		}
	}

	const messageResponseBytes = await getMessageCLFReportResponse({
		messageId: messageReportLog.decoded.args.messageId,
		messageHash: keccak256(messageLog.args.message),
		srcChainSelector: testClient.chain?.id.toString(),
		srcChainData: createSrcChainData(messageLog.args.sender, messageLogBlockNumber),
		operatorAddresses: getEnvVar("OPERATOR_ADDRESS"),
	});

	const clfRequestId = requestSentLog.log.topics[1];
	const clfReportBytes = getCLFReport(messageResponseBytes, clfRequestId, conceroVerifier);

	const decoded = decodeAbiParameters(
		[
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
		],
		clfReportBytes,
	);

	console.log("decoded", decoded);

	const clfDonReportSubmission = decoded[0];

	try {
		await testClient.writeContract({
			address: mockCLFRouter,
			abi: [...mockCLFRouterAbi, ...conceroVerifierAbi],
			functionName: "transmit",
			args: [
				clfDonReportSubmission.context,
				clfDonReportSubmission.report,
				clfDonReportSubmission.rs,
				clfDonReportSubmission.ss,
				clfDonReportSubmission.rawVs,
			],
		});
	} finally {
		await testClient.stopImpersonatingAccount({
			address: mockCLFRouter,
		});
	}
}
