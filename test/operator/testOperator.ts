import "./utils/configureOperatorEnv";
import { deployContracts } from "../../tasks";
import { ensureOperatorIsRegistered } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureOperatorIsRegistered";
import { ensureDeposit } from "@concero/v2-operators/src/relayer/a/contractCaller/ensureDeposit";
import { setupEventListeners } from "@concero/v2-operators/src/relayer/a/eventListener/setupEventListeners";
import { checkGas, getFallbackClients } from "@concero/v2-operators/src/relayer/common/utils";
import { setupOperatorRegistrationEventListener } from "./utils/setupEventListeners";
import { conceroNetworks } from "../../constants";
import deployConceroClientExample from "../../deploy/ConceroClientExample";
import deployMockCLFRouter from "../../deploy/MockCLFRouter";
import { compileContracts } from "../../utils";
import { parseUnits } from "viem";

/*
Testing pipeline:
1. in v2-contracts, run: bun run chain (to start hardhat node)
2. in v2-contracts, run: bun run operator-setup (to deploy contracts and set price feeds)
3. in v2-operators, run: bun ./src/relayer/a/index.ts (to start relayer)
*/

async function operator() {
    void (await checkGas());
    void (await ensureDeposit());
    void (await ensureOperatorIsRegistered());
    void (await setupEventListeners());
}

async function testOperator() {
    await compileContracts({ quiet: true });

    const mockCLFRouter = await deployMockRouter();
    await setupOperatorRegistrationEventListener({ mockCLFRouter: mockCLFRouter.address });
    const { conceroRouter } = await deployContracts(mockCLFRouter.address);
    await operator();
    const client = await deployClient(conceroRouter.address);
    await sendConceroMessage(client.address);
}

///
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

async function sendConceroMessage(clientAddress: string) {
    const hre = require("hardhat");
    const conceroNetwork = conceroNetworks[hre.network.name];
    const { walletClient } = await getFallbackClients(conceroNetwork);

    const { abi: exampleClientAbi } = await import(
        "../../artifacts/contracts/ConceroClient/ConceroClientExample.sol/ConceroClientExample.json"
    );

    const txHash = await walletClient.writeContract({
        address: clientAddress,
        abi: exampleClientAbi,
        functionName: "sendConceroMessage",
        args: [],
        account: walletClient.account,
        value: parseUnits("0.001", 18),
    });

    console.log(`Sent concero message with txHash ${txHash}`);
    return txHash;
}

testOperator();

// export { testOperator };
