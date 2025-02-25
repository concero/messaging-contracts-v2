import { Address, decodeEventLog, Hash, parseEther, TestClient, TransactionReceipt } from "viem";
import { getEnvVar, getTestClient } from "../../../utils";
import { privateKeyToAccount } from "viem/accounts";
import { decodeLogs } from "@concero/v2-operators/src/relayer/common/eventListener/decodeLogs";
import { globalConfig, networkEnvKeys } from "@concero/v2-operators/src/constants";
import { getOperatorRegistrationCLFResponse } from "../getOperatorRegistrationCLFResponse";
import { config } from "@concero/v2-operators/src/relayer/a/constants";
import { ExtendedTestClient } from "../../../utils/getViemClients";

export async function handleOperatorRegistration(testClient: ExtendedTestClient, txHash: Hash, mockCLFRouter: Address) {
    const receipt = await testClient.getTransactionReceipt({ hash: txHash });

    const decodedLogs = decodeLogs(receipt.logs, globalConfig.ABI.CONCERO_VERIFIER);

    const operatorRegistrationLog = decodedLogs.find(log => log.eventName === "OperatorRegistrationRequested");
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
    console.log(operatorRegistrationCLFResponseBytes);
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
