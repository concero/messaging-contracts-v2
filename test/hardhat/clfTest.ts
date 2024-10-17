import deployConceroRouter from "../../deploy/ConceroRouter";
import { getClients, getEnvVar } from "../../utils";
import { cNetworks, networkEnvKeys } from "../../constants";
import { approve } from "./utils/approve";
import { parseUnits } from "viem";

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
        const feeToken = getEnvVar(`USDC_${networkEnvKeys["base"]}`);
        const messageRequest = {
            feeToken,
            message: {
                dstChainSelector: getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA"),
                receiver: walletClient.account.address,
                tokenAmounts: [],
                relayers: [],
                data: walletClient.account.address,
                extraArgs: "0x01010",
            },
        };

        await approve(feeToken, deploymentAddress, parseUnits("1", 6), walletClient, publicClient);

        const hash = await walletClient.writeContract({
            address: deploymentAddress,
            abi: conceroRouterAbi,
            functionName: "sendMessage",
            account: walletClient.account,
            args: [messageRequest],
            chain: cNetworks.localhost.viemChain,
        });

        console.log("Message sent with hash:", hash);
    });
});
