import "./utils/configureOperatorEnv";
import { deployContracts } from "../../tasks";
import { ensureOperatorIsRegistered } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureOperatorIsRegistered";
import { ensureDeposit } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureDeposit";
import { setupEventListeners } from "@concero/v2-operators/src/relayer/a/eventListener/setupEventListeners";
import { checkGas } from "@concero/v2-operators/src/relayer/common/utils";
import { setupOperatorTestListeners } from "./utils/setupOperatorTestListeners";
import deployConceroClientExample from "../../deploy/ConceroClientExample";
import deployMockCLFRouter from "../../deploy/MockCLFRouter";
import { compileContracts } from "../../utils";

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

    const mockCLFRouter = await deployMockRouter();
    const { conceroRouter } = await deployContracts(mockCLFRouter.address);
    const conceroClientExample = await deployClient(conceroRouter.address);
    await setupOperatorTestListeners({
        mockCLFRouter: mockCLFRouter.address,
        conceroClientExample: conceroClientExample.address,
    });
    await operator();
}

async function deployMockRouter() {
    const hre = require("hardhat");
    const mockCLFRouter = await deployMockCLFRouter(hre);
    console.log(`Deployed MockCLFRouter at ${mockCLFRouter.address}`);
    return mockCLFRouter;
}

async function deployClient(conceroRouterAddress: string) {
    const hre = require("hardhat");
    const conceroClientExample = await deployConceroClientExample(hre, { conceroRouter: conceroRouterAddress });
    console.log(`Deployed ConceroClientExample at ${conceroClientExample.address}`);
    return conceroClientExample;
}

testOperator();
