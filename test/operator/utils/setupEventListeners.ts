import { networkEnvKeys } from "@concero/v2-operators/src/constants";
import { config } from "@concero/v2-operators/src/relayer/a/constants";
import { getEnvVar, getTestClient } from "../../../utils";
import { handleMessageReportRequest } from "./handleMessageReportRequest";
import { handleOperatorRegistration } from "./handleOperatorRegistration";
import { sendConceroMessage } from "./sendConceroMessage";
import { privateKeyToAccount } from "viem/accounts";

async function setupOperatorRegistrationEventListener({
    mockCLFRouter,
    conceroClientExample,
}: {
    mockCLFRouter: string;
    conceroClientExample: string;
}) {
    const network = config.networks.conceroVerifier;
    const conceroVerifier = getEnvVar(`CONCERO_VERIFIER_${networkEnvKeys[network.name]}`);
    const testClient = getTestClient(privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`));

    config.eventEmitter.on("requestOperatorRegistration", async ({ txHash }) => {
        await handleOperatorRegistration(testClient, txHash, mockCLFRouter);
    });

    config.eventEmitter.on("operatorRegistered", async ({ txHash }) => {
        await sendConceroMessage(testClient, testClient, conceroClientExample);
    });

    config.eventEmitter.on("requestMessageReport", async ({ txHash }) => {
        await handleMessageReportRequest(testClient, txHash, mockCLFRouter);
    });
}

export { setupOperatorRegistrationEventListener };
