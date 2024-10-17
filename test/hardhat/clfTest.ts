import deployConceroRouter from "../../deploy/ConceroRouter";
import { getClients, getEnvVar } from "../../utils";
import { cNetworks, networkEnvKeys } from "../../constants";

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

        const { publicClient, walletClient } = getClients(cNetworks.localhost.viemChain);

        const messageRequest = {
            feeToken: getEnvVar(`USDC_${networkEnvKeys["base"]}`),
            message: {
                dstChainSelector: getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA"),
                receiver: walletClient.account.address,
                tokenAmounts: [],
                relayers: [],
                data: "0x1",
                extraArgs: "0x0",
            },
        };

        const request = await publicClient.simulateContract({
            address: deploymentAddress,
            abi: conceroRouterAbi,
            functionName: "sendMessage",
            account: walletClient.account,
            args: [messageRequest],
            chain: cNetworks.localhost.viemChain,
        });
        const hash = await walletClient.writeContract(request);
        console.log("Message sent with hash:", hash);
    });
});
