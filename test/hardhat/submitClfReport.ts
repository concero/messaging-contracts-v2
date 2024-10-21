import { generateClfReport } from "./utils/generateClfReport";
import { getClients, getEnvVar } from "../../utils";
import { conceroNetworks } from "../../constants";
import { privateKeyToAccount } from "viem/accounts";
import { zeroHash } from "viem";
import { deployRouterTask } from "../../tasks/deployRouter/deployConceroRouter";

describe("ConceroRouter", () => {
    const hre = require("hardhat");
    before(async () => {
        await deployRouterTask({ deployProxy: true }, hre);
    });

    it("Should submit and decode clf report", async function () {
        const { abi: conceroRouterAbi } = await import(
            "../../../v2-operators/src/relayer/a/constants/ConceroRouter.json"
        );
        const { walletClient } = getClients(
            conceroNetworks.hardhat.viemChain,
            process.env.LOCALHOST_RPC_URL,
            privateKeyToAccount(`0x${process.env.TEST_DEPLOYER_PRIVATE_KEY}`),
        );

        const clfReport = await generateClfReport("clfFulfillResponse", walletClient);
        const message = {
            srcChainSelector: 1n,
            dstChainSelector: 2n,
            receiver: walletClient.account.address,
            sender: walletClient.account.address,
            tokenAmounts: [],
            relayers: [],
            data: zeroHash,
            extraArgs: zeroHash,
        };

        const hash = await walletClient.writeContract({
            address: getEnvVar("CONCERO_CLF_ROUTER_LOCALHOST"),
            functionName: "submitMessageReport",
            args: [clfReport, message],
            abi: conceroRouterAbi,
            chain: conceroNetworks.localhost.viemChain,
            account: walletClient.account,
            gas: 1000000n,
        });

        console.log(`Transaction hash: ${hash}`);
    });
});
