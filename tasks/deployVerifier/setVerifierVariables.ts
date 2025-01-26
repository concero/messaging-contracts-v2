import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { getEnvAddress, getFallbackClients, getWallet, log } from "../../utils";
import { conceroNetworks } from "../../constants";
import { ConceroNetwork, ConceroNetworkNames } from "../../types/ConceroNetwork";

async function setVerifierVariables(hre: HardhatRuntimeEnvironment) {
    const { live, name } = hre.network;
    const network = conceroNetworks[name as ConceroNetworkNames];

    await setAllowedOperators(hre, network);
}

async function setAllowedOperators(hre: HardhatRuntimeEnvironment, network: ConceroNetwork) {
    const { abi: CLFRouterAbi } = await import("../../artifacts/contracts/CLFRouter/CLFRouter.sol/CLFRouter.json");

    const { publicClient, walletClient, account } = getFallbackClients(network);
    const operatorAddress = getWallet(network.type, "operator", "address");
    const [clfRouter] = getEnvAddress("clfRouterProxy", network.name);

    const { request: registerOperatorRequest } = await publicClient.simulateContract({
        address: clfRouter,
        abi: CLFRouterAbi,
        functionName: "registerOperator",
        account,
        args: [operatorAddress],
    });

    const registerHash = await walletClient.writeContract(registerOperatorRequest);
    log(`Operator registered with hash: ${registerHash}`, "setConceroRouterVariables", network.name);
}

export { setVerifierVariables };
