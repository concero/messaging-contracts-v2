import deployConceroRouter from "../../deploy/ConceroRouter";
import { cNetworks, networkEnvKeys } from "../../constants";
import { getClients, getEnvVar } from "../../utils";
import { base } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";

const hre = require("hardhat");

let deploymentAddress = null;
describe("Concero Router", () => {
    it("Should deploy Concero Router", async function () {
        const deployment = await deployConceroRouter(hre);
        deploymentAddress = deployment.address;
        console.log("Concero Router deployed at:", deploymentAddress);
    });

    it("Should deploy the contract and call sendMessage", async function () {
        const { abi: conceroRouterAbi } = await import(
            "../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
        );

        const { publicClient, walletClient } = getClients(
            base,
            "http://127.0.0.1:8545",
            privateKeyToAccount("0x" + process.env.TESTS_WALLET_PRIVATE_KEY),
        );

        const message = {
            feeToken: getEnvVar(`USDC_${networkEnvKeys["base"]}`),
            message: "Hello World",
        };

        const request = await publicClient.simulateContract({
            address: deploymentAddress,
            abi: conceroRouterAbi,
            functionName: "sendMessage",
            account: walletClient.account,
            args: [message],
            chain: cNetworks.localhost,
        });
        const hash = await walletClient.writeContract(request);
        console.log("Message sent with hash:", hash);
    });
});
