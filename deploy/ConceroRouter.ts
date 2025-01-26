import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks, networkEnvKeys } from "../constants";
import updateEnvVariable from "../utils/updateEnvVariable";
import log from "../utils/log";
import { getEnvVar } from "../utils";
import { ConceroNetworkNames, NetworkType } from "../types/ConceroNetwork";
import { getGasParameters } from "../utils/getGasPrice";

function getCLFDonSigners(networkType: NetworkType) {
    let networkName: ConceroNetworkNames;
    switch (networkType) {
        case "mainnet":
            networkName = "base";
            break;

        case "testnet":
            networkName = "baseSepolia";
            break;

        case "localhost":
            networkName = "base";
            break;

        default:
            throw new Error(`Invalid network type: ${networkType}`);
    }

    let clfDonSigners = [];
    for (let i = 0; i < 4; i++) {
        clfDonSigners.push(getEnvVar(`CLF_DON_SIGNING_KEY_${i}_${networkEnvKeys[networkName]}`));
    }
    return clfDonSigners;
}

const deployRouter: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name, live } = hre.network;

    const chain = conceroNetworks[name as ConceroNetworkNames];
    const { type: networkType } = chain;

    const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

    // log("Deploying...", "deployRouter", name);

    const args = {
        usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
        chainSelector: getEnvVar(`CL_CCIP_CHAIN_SELECTOR_${networkEnvKeys[name]}`),
        owner: deployer,
    };

    const deployment = (await deploy("ConceroRouter", {
        from: deployer,
        args: [args.usdc, args.chainSelector, args.owner, ...getCLFDonSigners(networkType)],
        log: true,
        autoMine: true,
        maxFeePerGas,
        maxPriorityFeePerGas,
    })) as Deployment;

    log(`Deployed at: ${deployment.address}`, "deployRouter", name);
    updateEnvVariable(`CONCERO_ROUTER_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployRouter;
deployRouter.tags = ["ConceroRouter"];
