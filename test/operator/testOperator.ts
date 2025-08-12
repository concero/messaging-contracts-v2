import "./utils/configureOperatorEnv";

import { BlockManagerRegistry, Logger } from "@concero/operator-utils";
import { checkGas } from "@concero/v2-operators/src/common/utils";
import { initializeManagers } from "@concero/v2-operators/src/common/utils/initializeManagers";
import { ensureDeposit } from "@concero/v2-operators/src/relayer-a/businessLogic/ensureDeposit";
import { ensureOperatorIsRegistered, ensureOperatorIsRegisteredVoid } from "@concero/v2-operators/src/relayer-a/businessLogic/ensureOperatorIsRegistered";
import { setupEventListeners } from "@concero/v2-operators/src/relayer-a/eventListener/setupEventListeners";
import { privateKeyToAccount } from "viem/accounts";

import { MessagingDeploymentManager } from "@concero/v2-operators/src/common/managers/MessagingDeploymentManager";

import { deployConceroClientExample, deployMockCLFRouter } from "../../deploy";
import { deployContracts, setRouterSupportedChains } from "../../tasks";
import { buildClfJs } from "../../tasks/clf";
import { compileContracts, getTestClient } from "../../utils";
import { deployPseudoRemoteConceroRouter } from "./utils/deployPseudoRemoteConceroRouter";
import { setupOperatorTestListeners } from "./utils/setupOperatorTestListeners";

import { eventEmitter } from "../../constants";
import { globalConfig } from "@concero/v2-operators/src/constants/globalConfig";

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

async function clf() {
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

	await ensureOperatorIsRegisteredVoid();
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
		case "clf":
			await setupChain();
			await clf();
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
