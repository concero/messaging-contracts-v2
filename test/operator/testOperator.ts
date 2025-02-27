import "./utils/configureOperatorEnv";

import { ensureDeposit } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureDeposit";
import { ensureOperatorIsRegistered } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureOperatorIsRegistered";
import { setupEventListeners } from "@concero/v2-operators/src/relayer/a/eventListener/setupEventListeners";
import { checkGas } from "@concero/v2-operators/src/relayer/common/utils";

import deployConceroClientExample from "../../deploy/ConceroClientExample";
import deployMockCLFRouter from "../../deploy/MockCLFRouter";
import { deployContracts } from "../../tasks";
import { compileContracts } from "../../utils";
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
	const hre = require("hardhat");
	await compileContracts({ quiet: true });

	const mockCLFRouter = await deployMockCLFRouter(hre);

	const { conceroRouter } = await deployContracts(mockCLFRouter.address);
	const conceroClientExample = await deployConceroClientExample(hre, {
		conceroRouter: conceroRouter.address,
	});
	await setupOperatorTestListeners({
		mockCLFRouter: mockCLFRouter.address,
		conceroClientExample: conceroClientExample.address,
	});
	await operator();
}

testOperator();

// export { testOperator };
