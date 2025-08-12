import { Logger } from "@concero/operator-utils";
import { MessagingDeploymentManager } from "@concero/v2-operators/src/common/managers/MessagingDeploymentManager";
import { globalConfig } from "@concero/v2-operators/src/constants/globalConfig";
import hre from "hardhat";
import { Abi, Address, encodeAbiParameters, keccak256, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import { ErrorType } from "../../../clf/src/common/errorType";
import { deployConceroClientExample } from "../../../deploy";
import { setIsOperatorRegistered } from "../../../tasks";
import { getTestClient } from "../../../utils";
import { handleMessageReportRequestWithFinalization } from "./handleMessageReportRequestWithFinalization";
import { sendConceroMessage } from "./sendConceroMessage";

async function initializeManagers() {
	// Initialize logger
	const logger = Logger.createInstance({
		logDir: globalConfig.LOGGER.LOG_DIR,
		logMaxSize: globalConfig.LOGGER.LOG_MAX_SIZE,
		logMaxFiles: globalConfig.LOGGER.LOG_MAX_FILES,
		logLevelDefault: globalConfig.LOGGER.LOG_LEVEL_DEFAULT,
		logLevelsGranular: globalConfig.LOGGER.LOG_LEVELS_GRANULAR,
		enableConsoleTransport: process.env.NODE_ENV !== "production",
	});
	await logger.initialize();

	// Initialize messaging deployment manager
	const messagingDeploymentManager = MessagingDeploymentManager.createInstance(
		logger.getLogger("MessagingDeploymentManager"),
		{
			conceroDeploymentsUrl: globalConfig.URLS.CONCERO_DEPLOYMENTS,
			networkMode: "localhost",
		},
	);
	await messagingDeploymentManager.initialize();
}

function getAddresses() {
	// Get concero verifier and router addresses
	const conceroVerifier = process.env.CONCERO_VERIFIER_LOCALHOST;
	const conceroRouter = process.env.CONCERO_ROUTER_LOCALHOST;

	if (!conceroVerifier || !conceroRouter) {
		throw new Error("CONCERO_VERIFIER_LOCALHOST or CONCERO_ROUTER_LOCALHOST is undefined");
	}

	// Get test client
	const testClient = getTestClient(
		privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`),
	);

	if (!testClient.account) {
		throw new Error("testClient.account is undefined");
	}

	return { conceroVerifier, conceroRouter, testClient };
}

function createSrcChainData(sender: Address, blockNumber: bigint) {
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
		[{ sender, blockNumber }],
	);
}

async function setUpOperator(conceroVerifier: string, testClient: any, conceroVerifierAbi: Abi) {
	// Set operator as registered
	await setIsOperatorRegistered(
		conceroVerifier,
		testClient.account.address,
		testClient as any,
		true,
	);

	// Deposit operator
	const depositAmount = parseEther("1");
	await testClient.writeContract({
		account: testClient.account,
		address: conceroVerifier as `0x${string}`,
		abi: conceroVerifierAbi,
		functionName: "operatorDeposit",
		args: [testClient.account.address],
		value: depositAmount,
	});
}

export async function clfFinalizeSrcTest() {
	await initializeManagers();

	const { conceroVerifier, conceroRouter, testClient } = getAddresses();
	const { abi: conceroVerifierAbi } = await import(
		"../../../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);
	await setUpOperator(conceroVerifier, testClient, conceroVerifierAbi as Abi);

	// Deploy concero client example
	const conceroClientExample = await deployConceroClientExample(hre, {
		conceroRouter: conceroRouter,
	});

	// Send concero message
	const shouldFiniliseSrc = true;
	const messageResult = await sendConceroMessage(
		testClient as any,
		testClient as any,
		conceroClientExample.address,
		shouldFiniliseSrc,
	);

	if (!messageResult.messageId) {
		throw new Error("messageId is undefined in messageResult");
	}

	const messageId = messageResult.messageId;
	const messageHashSum = keccak256(messageResult.message);
	const srcChainSelector = 1;
	const encodedSrcChainData = createSrcChainData(
		conceroClientExample.address as `0x${string}`,
		messageResult.blockNumber,
	);

	// Request message report
	const requestMessageReportTxHash = await testClient.writeContract({
		account: testClient.account,
		address: conceroVerifier as `0x${string}`,
		abi: conceroVerifierAbi,
		functionName: "requestMessageReport",
		args: [messageId, messageHashSum, srcChainSelector, encodedSrcChainData],
	});

	// Handle message report request with finalization
	try {
		await handleMessageReportRequestWithFinalization(testClient, requestMessageReportTxHash);
	} catch (error: any) {
		if (error.message === ErrorType.FINALITY_NOT_REACHED) {
			console.log("--------------------------------------------------------------");
			console.log(
				`❌ FINALITY_NOT_REACHED: CLF returned a finalization error ${error.message}`,
			);
			console.log("--------------------------------------------------------------");

			// Mine 12 blocks to reach finality
			for (let i = 0; i < 12; i++) {
				await hre.network.provider.send("evm_mine");
			}
			console.log("\n12 blocks are mined ...");
			console.log("retrying requestMessageReportTxHash ... \n");

			try {
				await handleMessageReportRequestWithFinalization(
					testClient,
					requestMessageReportTxHash,
				);
				console.log("--------------------------------------------------------------");
				console.log(`✅ FINALITY_REACHED: CLF returned a result without error`);
				console.log("--------------------------------------------------------------");
			} catch (error: any) {
				console.log("--------------------------------------------------------------");
				console.log(
					`❌ FINALITY_NOT_REACHED: CLF returned a finalization error ${error.message}`,
				);
				console.log("--------------------------------------------------------------");
			}
		}
	}
}
