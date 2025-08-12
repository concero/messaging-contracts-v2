import { eventEmitter } from "@concero/v2-operators/src/constants";

import { setIsOperatorRegistered } from "../../../tasks/setIsOperatorRegistered";
import type { ExtendedTestClient } from "../../../utils/getViemClients";
import { handleMessageReportRequest } from "./handleMessageReportRequest";
import { handleOperatorRegistration } from "./handleOperatorRegistration";
import { sendConceroMessage } from "./sendConceroMessage";
import { parseEther } from "viem";

async function setupOperatorTestListeners({
	testClient,
	mockCLFRouter,
	conceroClientExample,
	conceroVerifier,
}: {
	testClient: ExtendedTestClient;
	mockCLFRouter: string;
	conceroClientExample: string;
	conceroVerifier: string;
}) {
	eventEmitter.on("requestOperatorRegistration", async ({ txHash }) => {
		await handleOperatorRegistration(testClient, txHash, mockCLFRouter);
	});

	eventEmitter.on("operatorRegistered", async () => {
		await sendConceroMessage(testClient, testClient, conceroClientExample);
	});

	eventEmitter.on("requestMessageReport", async ({ txHash }) => {
		await handleMessageReportRequest(
			testClient,
			txHash,
			mockCLFRouter,
			conceroVerifier,
			conceroClientExample,
		);
	});

	eventEmitter.on("messageReported", async () => {
		await setIsOperatorRegistered(
			conceroVerifier,
			testClient.account.address,
			testClient,
			true,
		);

		const messageResult = await sendConceroMessage(
			testClient,
			testClient as any,
			conceroClientExample,
		);

		console.log("[setupOperatorTestListeners]: messageResult:", messageResult);

		if (!messageResult.messageId) {
			throw new Error("messageId is undefined in messageResult");
		}

		const { abi: conceroVerifierAbi } = await import(
			"../../../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
		);

		const messageId = messageResult.messageId as `0x${string}`;
		const messageHashSum = messageId;
		const srcChainSelector = 1;
		const srcChainData = "0x00";

		console.log("[setupOperatorTestListeners]: requestMessageReport params:", {
			messageId,
			messageHashSum,
			srcChainSelector,
			srcChainData,
		});

		const depositAmount = parseEther("1");
		await testClient.writeContract({
			account: testClient.account,
			address: conceroVerifier as `0x${string}`,
			abi: conceroVerifierAbi,
			functionName: "operatorDeposit",
			args: [testClient.account.address],
			value: depositAmount,
		});
		console.log("[setupOperatorTestListeners]: Operator deposit completed");

		const requestMessageReportTxHash = await testClient.writeContract({
			account: testClient.account,
			address: conceroVerifier as `0x${string}`,
			abi: conceroVerifierAbi,
			functionName: "requestMessageReport",
			args: [messageId, messageHashSum, srcChainSelector, srcChainData],
		});

		await handleMessageReportRequest(
			testClient,
			requestMessageReportTxHash,
			mockCLFRouter,
			conceroVerifier,
			conceroClientExample,
		);
	});
}

export { setupOperatorTestListeners };
