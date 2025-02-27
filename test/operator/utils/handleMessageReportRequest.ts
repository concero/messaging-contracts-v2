import { Address, Hash, decodeAbiParameters, decodeEventLog } from "viem";

import { globalConfig } from "@concero/v2-operators/src/constants";

import { getEnvVar } from "../../../utils";
import { ExtendedTestClient } from "../../../utils/getViemClients";
import { getCLFReport } from "../getCLFReport";
import { getMessageCLFReportResponse } from "../getMessageCLFReportResponse";

export async function handleMessageReportRequest(
	testClient: ExtendedTestClient,
	txHash: Hash,
	mockCLFRouter: Address,
) {
	const { abi: mockCLFRouterAbi } = await import(
		"../../../artifacts/contracts/mocks/MockCLFRouter.sol/MockCLFRouter.json"
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
			});

			if (decoded.eventName === "MessageReportRequested") {
				messageReportLog = { log, decoded };
			} else if (decoded.eventName === "RequestSent") {
				requestSentLog = { log, decoded };
			}
		} catch {
			continue;
		}
	}

	if (!messageReportLog) {
		throw new Error("MessageReportRequested event not found");
	}

	if (!requestSentLog) {
		throw new Error("RequestSent event not found");
	}

	const messageResponseBytes = await getMessageCLFReportResponse({
		requester: getEnvVar("OPERATOR_ADDRESS"),
		requestId: requestSentLog.log.topics[1],
		internalMessageConfig: messageReportLog.decoded.args.internalMessageConfig.toString(),
		messageHashSum: messageReportLog.decoded.args.messageHashSum,
		srcChainData: messageReportLog.decoded.args.srcChainData,
		allowedOperators: [getEnvVar("OPERATOR_ADDRESS")],
	});

	const clfReportBytes = await getCLFReport(messageResponseBytes);
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

	const clfDonReportSubmission = decoded[0];

	try {
		await testClient.writeContract({
			address: mockCLFRouter,
			abi: mockCLFRouterAbi,
			functionName: "transmit",
			args: [
				clfDonReportSubmission.context,
				clfDonReportSubmission.report,
				clfDonReportSubmission.rs,
				clfDonReportSubmission.ss,
				clfDonReportSubmission.rawVs,
			],
			gasLimit: 1_000_000,
		});
	} finally {
		await testClient.stopImpersonatingAccount({
			address: mockCLFRouter,
		});
	}
}
