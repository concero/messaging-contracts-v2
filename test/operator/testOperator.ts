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

async function testOperator() {
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
	await operator();
}

testOperator();
