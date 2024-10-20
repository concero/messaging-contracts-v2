import { generateClfReport } from "./utils/generateClfReport";
import { getClients } from "../../utils";
import { conceroNetworks } from "../../constants";
import { privateKeyToAccount } from "viem/accounts";

const hre = require("hardhat");

describe("ConceroRouter", () => {
    // let deploymentAddress = "0x23494105b6B8cEaA0eB9c051b7e4484724641821";
    //
    // before(async () => {
    //     deploymentAddress = await deployConceroRouterWrapper();
    // });

    it("Should submit and decode clf report", async function () {
        const walletClient = getClients(
            conceroNetworks.hardhat,
            process.env.LOCALHOST_FORK_RPC_URL,
            privateKeyToAccount(`0x${process.env.TESTS_WALLET_PRIVATE_KEY}`),
        );

        await generateClfReport("clfFulfillResponse", walletClient);
    });
});
