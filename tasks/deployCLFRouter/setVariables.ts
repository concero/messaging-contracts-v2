import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { getEnvAddress, getFallbackClients, log } from "../../utils";
import { conceroNetworks } from "../../constants";
import { ConceroNetwork, ConceroNetworkNames } from "../../types/ConceroNetwork";

export async function setVariables(hre: HardhatRuntimeEnvironment) {
    const { live, name } = hre.network;
    const network = conceroNetworks[name as ConceroNetworkNames];
    if (live) {
        console.log("Setting variables...");
    } else {
        await setAllowedOperators(hre, network);
    }
}

async function setAllowedOperators(hre: HardhatRuntimeEnvironment, network: ConceroNetwork) {
    const { abi: CLFRouterAbi } = await import("../../artifacts/contracts/CLFRouter/CLFRouter.sol/CLFRouter.json");

    const { publicClient, walletClient, account } = getFallbackClients(network);

    const { deployer } = await hre.getNamedAccounts();
    const [clfRouter] = getEnvAddress("clfRouter", network.name);

    const { request: registerOperatorRequest } = await publicClient.simulateContract({
        address: clfRouter,
        abi: CLFRouterAbi,
        functionName: "registerOperator",
        account,
        args: [deployer],
    });

    const registerHash = await walletClient.writeContract(registerOperatorRequest);
    log(`Operator registered with hash: ${registerHash}`, "setConceroRouterVariables", network.name);
}
