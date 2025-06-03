import { eventEmitter } from "@concero/v2-operators/src/constants";

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
}

export { setupOperatorTestListeners };
