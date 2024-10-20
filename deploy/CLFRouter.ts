import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployment } from "hardhat-deploy/types";
import { getEnvVar, getHashSum, updateEnvVariable } from "../utils";
import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import log from "../utils/log";

const ETHERS_JS_URL = "https://raw.githubusercontent.com/ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js";

const deployCLFRouter: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
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

    log("Deploying...", "deployCLFRouter", name);

    const args = {
        functionsRouter: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
        clfDonId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
        clfSubscriptionId: getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`),
        clfDonHostedSecretsVersion: getEnvVar(`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`),
        clfDonHostedSecretsSlotId: 0n,
        ethersJsCodeHash: getHashSum(ETHERS_JS_URL),
        requestCLFMessageReportJsCodeHash: getHashSum("../clf/dist/requestReport.js"),
        owner: deployer,
    };

    const deployment = (await deploy("CLFRouter", {
        from: deployer,
        args: [
            args.functionsRouter,
            args.clfDonId,
            args.clfSubscriptionId,
            args.clfDonHostedSecretsVersion,
            args.clfDonHostedSecretsSlotId,
            args.ethersJsCodeHash,
            args.requestCLFMessageReportJsCodeHash,
            args.owner,
        ],
        log: true,
        autoMine: true,
        maxFeePerGas,
        maxPriorityFeePerGas,
        // gasPrice, // Uncomment if custom gas price is needed
    })) as Deployment;

    log(`Deployed at: ${deployment.address}`, "deployCLFRouter", name);
    updateEnvVariable(`CONCERO_CLF_ROUTER_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployCLFRouter;
deployCLFRouter.tags = ["CLFRouter"];
