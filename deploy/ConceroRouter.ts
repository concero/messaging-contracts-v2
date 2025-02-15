import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames, NetworkType } from "../types/ConceroNetwork";
import { getGasParameters, updateEnvVariable, getEnvVar, log } from "../utils/";

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

type DeployArgs = {
    chainSelector: string;
    usdc: string;
    clfSigners: string[];
};

type DeploymentFunction = (hre: HardhatRuntimeEnvironment, overrideArgs?: Partial<DeployArgs>) => Promise<Deployment>;

const deployRouter: DeploymentFunction = async function (
    hre: HardhatRuntimeEnvironment,
    overrideArgs?: Partial<DeployArgs>,
): Promise<Deployment> {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name } = hre.network;

    const chain = conceroNetworks[name as ConceroNetworkNames];
    const { type: networkType } = chain;

    const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

    const defaultArgs: DeployArgs = {
        chainSelector: getEnvVar(`CONCERO_CHAIN_SELECTOR_${networkEnvKeys[name]}`),
        usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
        clfSigners: getCLFDonSigners(networkType),
    };

    const args: DeployArgs = {
        ...defaultArgs,
        ...overrideArgs,
    };

    const deployment = await deploy("ConceroRouter", {
        from: deployer,
        args: [args.chainSelector, args.usdc, args.clfSigners],
        log: true,
        autoMine: true,
        maxFeePerGas,
        maxPriorityFeePerGas,
    });

    log(`Deployed at: ${deployment.address}`, "deployRouter", name);
    updateEnvVariable(`CONCERO_ROUTER_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployRouter;
deployRouter.tags = ["ConceroRouter"];
