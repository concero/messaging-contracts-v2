import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployment } from "hardhat-deploy/types";
import { getEnvVar, getFallbackClients, getHashSum, updateEnvVariable } from "../utils";
import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";

const ETHERS_JS_URL = "https://raw.githubusercontent.com/ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js";

const deployCLFRouter: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;

    const { name, live } = hre.network;

    const chain = conceroNetworks[name as ConceroNetworkNames];
    const { type: networkType } = chain;

    console.log("Deploying...", "deployCLFRouter", name);

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

    const { publicClient } = getFallbackClients(chain);
    const gasPrice = String(await publicClient.getGasPrice());

    const clfRouterDeploy = (await deploy("CLFRouter", {
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
        // gasPrice, // Uncomment if custom gas price is needed
    })) as Deployment;

    console.log(`Deployed at: ${clfRouterDeploy.address}`, "deployCLFRouter", name);

    if (live) {
        updateEnvVariable(`CLF_ROUTER_${networkEnvKeys[name]}`, clfRouterDeploy.address, `deployments.${networkType}`);
    }

    return clfRouterDeploy;
};

export default deployCLFRouter;
deployCLFRouter.tags = ["CLFRouter"];
