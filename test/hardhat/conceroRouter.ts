import { conceroNetworks } from "../../constants";
import { getEnvVar, getFallbackClients } from "../../utils";
import { Address } from "viem";
import deployConceroRouter from "../../deploy/ConceroRouter";
import { privateKeyToAccount } from "viem/accounts";

const hre = require("hardhat");

const { publicClient, walletClient, account } = getFallbackClients(
    conceroNetworks[hre.network.name],
    privateKeyToAccount("0x" + process.env.TESTS_WALLET_PRIVATE_KEY),
);

describe("Concero Router", async () => {
    let conceroRouter: Address;
    let deployerAddress: Address;

    before(async function () {
        const { deployer } = await hre.getNamedAccounts();
        deployerAddress = deployer;

        await hre.network.provider.send("hardhat_setBalance", [deployer, "0x1000000000000000000000000"]);

        const { address } = await deployConceroRouter(hre);
        conceroRouter = address;
    });

    it("Should set allowed operator to deployer address", async function () {
        const { abi: conceroRouterAbi } = await import(
            "../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
        );

        // Call registerOperator from the owner (deployer) account
        const { request: registerOperatorRequest } = await publicClient.simulateContract({
            address: conceroRouter,
            abi: conceroRouterAbi,
            functionName: "registerOperator",
            account,
            args: [deployerAddress],
        });

        const registerHash = await walletClient.writeContract(registerOperatorRequest);
        console.log("Operator registered with hash:", registerHash);
    });

    it("Should send a message using sendMessage", async function () {
        const { abi: conceroRouterAbi } = await import(
            "../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
        );

        const message = {
            feeToken: "0x0000000000000000000000000000000000000000",
            message: "Hello World",
            dstChainSelector: getEnvVar(`CL_CCIP_CHAIN_SELECTOR_BASE`),
            receiver: deployerAddress,
            tokenAmounts: [],
            relayers: [],
            data: "0x", // Example data
            extraArgs: "0x", // Example extra args
        };

        // Send the message using the deployer (who is now the allowed operator)
        const { request: sendMessageRequest } = await publicClient.simulateContract({
            address: conceroRouter,
            abi: conceroRouterAbi,
            functionName: "sendMessage",
            account,
            args: [message],
            value: 50_000n,
        });

        const sendMessageHash = await walletClient.writeContract(sendMessageRequest);
        console.log("Message sent with hash:", sendMessageHash);
    });
});
