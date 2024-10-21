import { conceroNetworks } from "../../constants";
import { getEnvAddress, getEnvVar, getFallbackClients } from "../../utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";

describe("Concero Router", async () => {
    const hre: HardhatRuntimeEnvironment = require("hardhat");
    const { publicClient, walletClient, account } = getFallbackClients(conceroNetworks[hre.network.name]);

    it("Should send a message using sendMessage", async function () {
        const { abi: conceroRouterAbi } = await import(
            "../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
        );

        const message = {
            feeToken: "0x0000000000000000000000000000000000000000",
            dstChainSelector: getEnvVar(`CL_CCIP_CHAIN_SELECTOR_BASE`),
            receiver: account.address,
            tokenAmounts: [],
            relayers: [],
            data: "0x1637A2cafe89Ea6d8eCb7cC7378C023f25c892b6",
            extraArgs: "0x", // Example extra args
        };

        const [targetContract] = getEnvAddress("routerProxy", hre.network.name);
        // Send the message using the deployer (who is now the allowed operator)
        const { request: sendMessageRequest } = await publicClient.simulateContract({
            address: targetContract,
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
