import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployment } from "hardhat-deploy/types";
import { getEnvVar, getHashSum, updateEnvVariable } from "../utils";
import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import log from "../utils/log";
import { getGasParameters } from "../utils/getGasPrice";

const ETHERS_JS_URL = "https://raw.githubusercontent.com/ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js";
const requestReportJsUrl =
    "https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js";

const deployVerifier: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name } = hre.network;

    const chain = conceroNetworks[name as ConceroNetworkNames];
    const { type: networkType } = chain;

    const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

    const ethersJsCode = await fetch(ETHERS_JS_URL).then(res => res.text());
    const requestCLFMessageReportJsCode = await fetch(requestReportJsUrl).then(res => res.text());

    const args = {
        functionsRouter: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
        clfDonId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
        clfSubscriptionId: getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`),
        clfDonHostedSecretsVersion: getEnvVar(`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`),
        clfDonHostedSecretsSlotId: 0n,
        ethersJsCodeHash: getHashSum(ethersJsCode),
        requestCLFMessageReportJsCodeHash: getHashSum(requestCLFMessageReportJsCode),
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
    })) as Deployment;

    log(`Deployed at: ${deployment.address}`, "deployVerifier", name);
    updateEnvVariable(`CONCERO_CLF_ROUTER_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployVerifier;
deployVerifier.tags = ["ConceroVerifier"];
