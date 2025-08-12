import "./utils/configureOperatorEnv";

import { BlockManagerRegistry } from "@concero/operator-utils";
import { checkGas } from "@concero/v2-operators/src/common/utils";
import { initializeManagers } from "@concero/v2-operators/src/common/utils/initializeManagers";
import { ensureDeposit } from "@concero/v2-operators/src/relayer-a/businessLogic/ensureDeposit";
import { ensureOperatorIsRegistered } from "@concero/v2-operators/src/relayer-a/businessLogic/ensureOperatorIsRegistered";
import { setupEventListeners } from "@concero/v2-operators/src/relayer-a/eventListener/setupEventListeners";
import { privateKeyToAccount } from "viem/accounts";

import { deployConceroClientExample, deployMockCLFRouter } from "../../deploy";
import { deployContracts } from "../../tasks";
import { buildClfJs } from "../../tasks/clf";
import { compileContracts, getTestClient } from "../../utils";
import { clfFinalizeSrcTest as clfFinalizeSrcTestLogic } from "./utils/clfFinalizeSrcTest";
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

	const { conceroRouter, conceroVerifier } = await deployContracts(
		mockCLFRouter.address as `0x${string}`,
	);

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
	await clfFinalizeSrcTestLogic();
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
