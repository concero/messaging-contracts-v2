import "./utils/configureOperatorEnv";

import { privateKeyToAccount } from "viem/accounts";

import { ensureDeposit } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureDeposit";
import { ensureOperatorIsRegistered } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureOperatorIsRegistered";
import { setupEventListeners } from "@concero/v2-operators/src/relayer/a/eventListener/setupEventListeners";
import { checkGas } from "@concero/v2-operators/src/relayer/common/utils";

import { deployConceroClientExample } from "../../deploy";
import { deployMockCLFRouter } from "../../deploy";
import { deployContracts } from "../../tasks";
import { getTestClient } from "../../utils";
import { compileContracts } from "../../utils/compileContracts";
import { setupOperatorTestListeners } from "./utils/setupOperatorTestListeners";

/*
Testing pipeline:
1. in v2-contracts, run: bun run chain (to start hardhat node)
2. in v2-contracts, run: bun run operator-setup (to deploy contracts and set price feeds)
3. in v2-operators, run: bun ./src/relayer/a/index.ts (to start relayer)
*/

async function operator() {
	await checkGas();
	await ensureDeposit();
	await ensureOperatorIsRegistered();
	await setupEventListeners();
}

async function setupChain() {
	compileContracts({ quiet: true });
	const hre = require("hardhat");
	const testClient = getTestClient(
		privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`),
	);

	testClient.mine({ blocks: 1000 });

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

if (require.main === module) {
	main().catch(error => {
		console.error(error);
		process.exit(1);
	});
}
