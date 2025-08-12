import "./utils/configureOperatorEnv";

import { BlockManagerRegistry, Logger } from "@concero/operator-utils";
import { MessagingDeploymentManager } from "@concero/v2-operators/src/common/managers/MessagingDeploymentManager";
import { checkGas } from "@concero/v2-operators/src/common/utils";
import { initializeManagers } from "@concero/v2-operators/src/common/utils/initializeManagers";
import { globalConfig } from "@concero/v2-operators/src/constants/globalConfig";
import { ensureDeposit } from "@concero/v2-operators/src/relayer-a/businessLogic/ensureDeposit";
import { ensureOperatorIsRegistered } from "@concero/v2-operators/src/relayer-a/businessLogic/ensureOperatorIsRegistered";
import { setupEventListeners } from "@concero/v2-operators/src/relayer-a/eventListener/setupEventListeners";
import { encodeAbiParameters, keccak256, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import { ErrorType } from "../../clf/src/common/errorType";
import { deployConceroClientExample, deployMockCLFRouter } from "../../deploy";
import { deployContracts, setIsOperatorRegistered, setRouterSupportedChains } from "../../tasks";
import { buildClfJs } from "../../tasks/clf";
import { compileContracts, getEnvVar, getTestClient } from "../../utils";
import { handleMessageReportRequestWithFinalization } from "./utils/handleMessageReportRequestWithFinalization";
import { sendConceroMessage } from "./utils/sendConceroMessage";
import { setupOperatorTestListeners } from "./utils/setupOperatorTestListeners";

async function operator() {
	await initializeManagers();

	await checkGas();
	await ensureDeposit();
	await ensureOperatorIsRegistered();
	await setupEventListeners();

	const blockManagerRegistry = BlockManagerRegistry.getInstance();
	for (const blockManager of blockManagerRegistry.getAllBlockManagers()) {
		await blockManager.startPolling();
	}
}

async function setupChain() {
	compileContracts({ quiet: true });
	buildClfJs("arbitrumSepolia");

	const hre = require("hardhat");

	const testClient = getTestClient(
		privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`),
	);

	const mockCLFRouter = await deployMockCLFRouter(hre);

	const { conceroRouter, conceroVerifier } = await deployContracts(mockCLFRouter.address);

	const conceroClientExample = await deployConceroClientExample(hre, {
		conceroRouter: conceroRouter.address,
	});

	await setupOperatorTestListeners({
		testClient,
		mockCLFRouter: mockCLFRouter.address,
		conceroClientExample: conceroClientExample.address,
		conceroVerifier: conceroVerifier.address,
	});

	return { testClient, mockCLFRouter, conceroRouter, conceroVerifier, conceroClientExample };
}

async function clfFinalizeSrcTest() {
	const logger = Logger.createInstance({
		logDir: globalConfig.LOGGER.LOG_DIR,
		logMaxSize: globalConfig.LOGGER.LOG_MAX_SIZE,
		logMaxFiles: globalConfig.LOGGER.LOG_MAX_FILES,
		logLevelDefault: globalConfig.LOGGER.LOG_LEVEL_DEFAULT,
		logLevelsGranular: globalConfig.LOGGER.LOG_LEVELS_GRANULAR,
		enableConsoleTransport: process.env.NODE_ENV !== "production",
	});
	await logger.initialize();

	const messagingDeploymentManager = MessagingDeploymentManager.createInstance(
		logger.getLogger("MessagingDeploymentManager"),
		{
			conceroDeploymentsUrl: globalConfig.URLS.CONCERO_DEPLOYMENTS,
			networkMode: "localhost",
		},
	);
	await messagingDeploymentManager.initialize();

	const conceroVerifier = await messagingDeploymentManager.getConceroVerifier();
	const conceroRouter = await getEnvVar(`CONCERO_ROUTER_LOCALHOST`);
	const testClient = getTestClient(
		privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`),
	);

	await setIsOperatorRegistered(conceroVerifier, testClient.account.address, testClient, true);

	const hre = require("hardhat");

	const conceroClientExample = await deployConceroClientExample(hre, {
		conceroRouter: conceroRouter,
	});

	const shouldFiniliseSrc = true;
	const messageResult = await sendConceroMessage(
		testClient,
		testClient as any,
		conceroClientExample.address,
		shouldFiniliseSrc,
	);

	if (!messageResult.messageId) {
		throw new Error("messageId is undefined in messageResult");
	}

	const { abi: conceroVerifierAbi } = await import(
		"../../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const depositAmount = parseEther("1");
	await testClient.writeContract({
		account: testClient.account,
		address: conceroVerifier as `0x${string}`,
		abi: conceroVerifierAbi,
		functionName: "operatorDeposit",
		args: [testClient.account.address],
		value: depositAmount,
	});

	const messageId = messageResult.messageId;
	const messageHashSum = keccak256(messageResult.message);
	const srcChainSelector = 1;
	const encodedSrcChainData = encodeAbiParameters(
		[
			{
				type: "tuple",
				components: [
					{ name: "blockNumber", type: "uint256" },
					{ name: "sender", type: "address" },
				],
			},
		],
		[
			{
				blockNumber: messageResult.blockNumber,
				sender: conceroClientExample.address as `0x${string}`,
			},
		],
	);

	const requestMessageReportTxHash = await testClient.writeContract({
		account: testClient.account,
		address: conceroVerifier as `0x${string}`,
		abi: conceroVerifierAbi,
		functionName: "requestMessageReport",
		args: [messageId, messageHashSum, srcChainSelector, encodedSrcChainData],
	});

	try {
		await handleMessageReportRequestWithFinalization(testClient, requestMessageReportTxHash);
	} catch (error) {
		if (error.message === ErrorType.FINALITY_NOT_REACHED) {
			console.log("--------------------------------------------------------------");
			console.log(
				`✅ FINALITY_NOT_REACHED: CLF returned a finalization error ${error.message}`,
			);
			console.log("--------------------------------------------------------------");
		}
	}
}

async function main() {
	const args = process.argv.slice(2);
	const mode = args[0] ? args[0].toLowerCase() : null;

	switch (mode) {
		case "chain":
			await setupChain();
			break;
		case "operator":
			await operator();
			break;
		case "finalize-src":
			await setupChain();
			await clfFinalizeSrcTest();
			break;
		case null:
			await setupChain();
			await operator();
			break;
		default:
			console.error(
				"Please specify a mode: 'chain' (setup chain), 'run' (operator logic), or '' (both)",
			);
			process.exit(1);
	}
}

main();
