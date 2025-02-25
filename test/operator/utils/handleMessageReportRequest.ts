import { Address, decodeEventLog, Hash, parseEther, PublicClient, TestClient } from "viem";
import { getEnvVar, getTestClient } from "../../../utils";
import { privateKeyToAccount } from "viem/accounts";
import { globalConfig, networkEnvKeys } from "@concero/v2-operators/src/constants";
import { getMessageCLFReportResponse } from "../getMessageCLFReportResponse";
import { config } from "@concero/v2-operators/src/relayer/a/constants";
import { ExtendedTestClient } from "../../../utils/getViemClients";

export async function handleMessageReportRequest(testClient: ExtendedTestClient, txHash: Hash, mockCLFRouter: Address) {
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
            args: [requestSentLog.log.topics[1], messageResponseBytes, "0x"],
            account: mockCLFRouter,
            gasLimit: 1_000_000,
        });
    } finally {
        await testClient.stopImpersonatingAccount({
            address: mockCLFRouter,
        });
    }
}
