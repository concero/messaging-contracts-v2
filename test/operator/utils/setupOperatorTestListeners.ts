import { config } from "@concero/v2-operators/src/relayer/a/constants";

import type { ExtendedTestClient } from "../../../utils/getViemClients";
import { handleMessageReportRequest } from "./handleMessageReportRequest";
import { handleOperatorRegistration } from "./handleOperatorRegistration";
import { sendConceroMessage } from "./sendConceroMessage";

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
	config.eventEmitter.on("requestOperatorRegistration", async ({ txHash }) => {
		await handleOperatorRegistration(testClient, txHash, mockCLFRouter);
	});

	config.eventEmitter.on("operatorRegistered", async ({ txHash }) => {
		await sendConceroMessage(testClient, testClient, conceroClientExample);
	});

	config.eventEmitter.on("requestMessageReport", async ({ txHash }) => {
		await handleMessageReportRequest(testClient, txHash, mockCLFRouter, conceroVerifier);
	});
}

export { setupOperatorTestListeners };
