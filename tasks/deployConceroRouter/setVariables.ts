import { HardhatRuntimeEnvironment } from "hardhat/types";
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
    const { abi: conceroRouterAbi } = await import(
        "../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
    );

    const { publicClient, walletClient, account } = getFallbackClients(network);
    const { deployer } = await hre.getNamedAccounts();
    const [conceroRouter] = getEnvAddress("router", network.name);

    const { request: registerOperatorRequest } = await publicClient.simulateContract({
        address: conceroRouter,
        abi: conceroRouterAbi,
        functionName: "registerOperator",
        account,
        args: [deployer],
    });

    const registerHash = await walletClient.writeContract(registerOperatorRequest);
    log(`Operator registered with hash: ${registerHash}`, "setConceroRouterVariables", network.name);
}
