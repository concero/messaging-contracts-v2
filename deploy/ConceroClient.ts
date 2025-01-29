import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployment } from "hardhat-deploy/types";
import { getEnvVar, updateEnvVariable } from "../utils";
import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import log from "../utils/log";

const deployConceroClient: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name } = hre.network;
    const chain = conceroNetworks[name as ConceroNetworkNames];
    const { type: networkType } = chain;

    const args = {
        conceroRouter: getEnvVar(`CONCERO_ROUTER_PROXY_${networkEnvKeys[name]}`),
        chainSelector: 1n,
    };

    // Changed from "ConceroClient" to "ExampleClient"
    const deployment = await deploy("ExampleClient", {
        from: deployer,
        args: [args.conceroRouter, args.chainSelector],
        log: true,
        autoMine: true,
    });

    log(`Deployed at: ${deployment.address}`, "deployDemoClient", name);
    updateEnvVariable(`CONCERO_DEMO_CLIENT_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployConceroClient;
deployConceroClient.tags = ["ConceroClient"];
