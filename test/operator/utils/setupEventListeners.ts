import { Address, decodeEventLog, TransactionReceipt, parseEther, parseUnits } from "viem";
import { decodeLogs } from "@concero/v2-operators/src/relayer/common/eventListener/decodeLogs";
import { getCLFReport, getOperatorRegistrationCLFResponse } from "../getOperatorRegistrationCLFResponse";
import { conceroNetworks, globalConfig, networkEnvKeys } from "@concero/v2-operators/src/constants";
import { config } from "@concero/v2-operators/src/relayer/a/constants";
import { getEnvVar, getFallbackClients } from "../../../utils";
import { getTestClient } from "../../../utils";
import { privateKeyToAccount } from "viem/accounts";
import { WalletClient } from "viem";

const OPERATOR_REGISTRY_EVENT = "OperatorRegistrationRequested";

async function handleOperatorRegistration(receipt: TransactionReceipt, mockCLFRouter: Address) {
    const testClient = getTestClient(privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`));
    const decodedLogs = decodeLogs(receipt.logs, globalConfig.ABI.CONCERO_VERIFIER);

    const operatorRegistrationLog = decodedLogs.find(log => log.eventName === OPERATOR_REGISTRY_EVENT);
    if (!operatorRegistrationLog) return;

    const requestSentLog = receipt.logs.find(log => {
        try {
            const decoded = decodeEventLog({
                abi: globalConfig.ABI.CONCERO_VERIFIER,
                data: log.data,
                topics: log.topics,
            });
            return decoded.eventName === "RequestSent";
        } catch {
            return false;
        }
    });

    if (!requestSentLog) {
        throw new Error("RequestSent event not found");
    }

    const operatorRegistrationCLFResponseBytes = await getOperatorRegistrationCLFResponse();
    // const clfReport = await getCLFReport(operatorRegistrationCLFResponseBytes);

    const conceroVerifierAddress = getEnvVar(
        `CONCERO_VERIFIER_${networkEnvKeys[config.networks.conceroVerifier.name]}`,
    );

    await testClient.setBalance({
        address: mockCLFRouter,
        value: parseEther("10000"),
    });

    await testClient.impersonateAccount({ address: mockCLFRouter });

    try {
        await testClient.writeContract({
            address: conceroVerifierAddress,
            abi: globalConfig.ABI.CONCERO_VERIFIER,
            functionName: "handleOracleFulfillment",
            args: [requestSentLog.topics[1], operatorRegistrationCLFResponseBytes, "0x"],
            account: mockCLFRouter,
        });
    } finally {
        await testClient.stopImpersonatingAccount({
            address: mockCLFRouter,
        });
    }
}

async function sendConceroMessage(walletClient: WalletClient, clientAddress: string) {
    console.log("Sending concero message");
    const { abi: exampleClientAbi } = await import(
        "../../../artifacts/contracts/ConceroClient/ConceroClientExample.sol/ConceroClientExample.json"
    );

    const txHash = await walletClient.writeContract({
        address: clientAddress,
        abi: exampleClientAbi,
        functionName: "sendConceroMessage",
        args: [],
        account: privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`),
        value: parseUnits("0.001", 18),
    });

    console.log(`Sent concero message with txHash ${txHash}`);
    return txHash;
}

async function setupOperatorRegistrationEventListener({
    mockCLFRouter,
    conceroClientExample,
}: {
    mockCLFRouter: string;
    conceroClientExample: string;
}) {
    const network = config.networks.conceroVerifier;
    const conceroVerifier = getEnvVar(`CONCERO_VERIFIER_${networkEnvKeys[network.name]}`);
    const testClient = getTestClient();

    config.eventEmitter.on("requestOperatorRegistration", async ({ txHash }) => {
        const receipt = await testClient.getTransactionReceipt({ hash: txHash });
        await handleOperatorRegistration(receipt, mockCLFRouter);
    });

    config.eventEmitter.on("operatorRegistered", async ({ txHash }) => {
        await sendConceroMessage(testClient, conceroClientExample);
    });
}

export { setupOperatorRegistrationEventListener };
