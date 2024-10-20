import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks, networkEnvKeys } from "../constants";
import updateEnvVariable from "../utils/updateEnvVariable";
import log from "../utils/log";
import { getEnvVar } from "../utils";
import { ConceroNetworkNames } from "../types/ConceroNetwork";

const deployConceroRouter: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name, live } = hre.network;

    const chain = conceroNetworks[name as ConceroNetworkNames];
    const { type: networkType } = chain;

    const gasPrice = await hre.ethers.provider.getGasPrice();
    const maxFeePerGas = gasPrice.mul(2); // Set it to twice the base fee
    const maxPriorityFeePerGas = hre.ethers.utils.parseUnits("2", "gwei"); // Set a priority fee

    log("Deploying...", "deployConceroRouter", name);

    const args = {
        usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
        chainSelector: getEnvVar(`CL_CCIP_CHAIN_SELECTOR_${networkEnvKeys[name]}`),
        owner: deployer,
        clfDonSigner_0: getEnvVar(`CLF_DON_SIGNING_KEY_0_${networkEnvKeys[name]}`),
        clfDonSigner_1: getEnvVar(`CLF_DON_SIGNING_KEY_1_${networkEnvKeys[name]}`),
        clfDonSigner_2: getEnvVar(`CLF_DON_SIGNING_KEY_2_${networkEnvKeys[name]}`),
        clfDonSigner_3: getEnvVar(`CLF_DON_SIGNING_KEY_3_${networkEnvKeys[name]}`),
    };

    const deployment = (await deploy("ConceroRouter", {
        from: deployer,
        args: [
            args.usdc,
            args.chainSelector,
            args.owner,
            args.clfDonSigner_0,
            args.clfDonSigner_1,
            args.clfDonSigner_2,
            args.clfDonSigner_3,
        ],
        log: true,
        autoMine: true,
        maxFeePerGas,
        maxPriorityFeePerGas,
    })) as Deployment;

    log(`Deployed at: ${deployment.address}`, "deployConceroRouter", name);
    updateEnvVariable(`CONCERO_ROUTER_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployConceroRouter;
deployConceroRouter.tags = ["ConceroRouter"];
