import { Address, Hash, decodeEventLog, parseEther } from "viem";

import { globalConfig, networkEnvKeys } from "@concero/v2-operators/src/constants";
import { config } from "@concero/v2-operators/src/relayer/a/constants";
import { decodeLogs } from "@concero/v2-operators/src/relayer/common/eventListener/decodeLogs";

import { ChainType } from "../../../clf/src/common/enums";
import { OperatorRegistrationAction } from "../../../clf/src/operatorRegistration/types";
import { getEnvVar } from "../../../utils";
import { ExtendedTestClient } from "../../../utils/getViemClients";
import { getOperatorRegistrationCLFResponse } from "../getOperatorRegistrationCLFResponse";

export async function handleOperatorRegistration(
	testClient: ExtendedTestClient,
	txHash: Hash,
	mockCLFRouter: Address,
) {
	const receipt = await testClient.getTransactionReceipt({ hash: txHash });

	const decodedLogs = decodeLogs(receipt.logs, globalConfig.ABI.CONCERO_VERIFIER);

	const operatorRegistrationLog = decodedLogs.find(
		log => log.eventName === "OperatorRegistrationRequested",
	);
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

	const operatorRegistrationCLFResponseBytes = await getOperatorRegistrationCLFResponse({
		chainTypes: [ChainType.EVM],
		actions: [OperatorRegistrationAction.REGISTER],
		operatorAddresses: [getEnvVar("TESTNET_OPERATOR_ADDRESS")],
		requester: getEnvVar("TESTNET_OPERATOR_ADDRESS"),
	});

	const conceroVerifierAddress = getEnvVar(
		`CONCERO_VERIFIER_PROXY_${networkEnvKeys[config.networks.conceroVerifier.name]}`,
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
