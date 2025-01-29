import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployment } from "hardhat-deploy/types";
import { getEnvVar, getHashSum, updateEnvVariable } from "../utils";
import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import log from "../utils/log";
import { getGasParameters } from "../utils/getGasPrice";

const requestReportJsUrl =
    "https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestReport.min.js";
const requestOperatorRegistrationJsUrl =
    "https://raw.githubusercontent.com/concero/v2-contracts/refs/heads/master/clf/dist/requestOperatorRegistration.min.js";

const deployVerifier: (hre: HardhatRuntimeEnvironment) => Promise<Deployment> = async function (
    hre: HardhatRuntimeEnvironment,
) {
    const { deployer } = await hre.getNamedAccounts();
    const { deploy } = hre.deployments;
    const { name } = hre.network;

    const chain = conceroNetworks[name as ConceroNetworkNames];
    const { type: networkType } = chain;

    const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

    const requestCLFMessageReportJsCode = await fetch(requestReportJsUrl).then(res => res.text());
    const requestOperatorRegistrationJsCode = await fetch(requestOperatorRegistrationJsUrl).then(res => res.text());

    const args = {
        chainSelector: getEnvVar(`CONCERO_CHAIN_SELECTOR_${networkEnvKeys[name]}`),
        usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
        clfRouter: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
        clfDonId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
        clfSubscriptionId: getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`),
        clfDonHostedSecretsVersion: getEnvVar(`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`),
        clfDonHostedSecretsSlotId: "0",
        clfPremiumFeeUsdBps: getEnvVar(`CLF_PREMIUM_FEE_USD_BPS_${networkEnvKeys[name]}`),
        clfCallbackGasLimit: 100_000n,
        requestCLFMessageReportJsCodeHash: getHashSum(requestCLFMessageReportJsCode),
        requestOperatorRegistrationJsCodeHash: getHashSum(requestOperatorRegistrationJsCode),
    };

    const deployment = (await deploy("ConceroVerifier", {
        from: deployer,
        args: [
            args.chainSelector,
            args.usdc,
            args.clfRouter,
            args.clfDonId,
            args.clfSubscriptionId,
            args.clfDonHostedSecretsVersion,
            args.clfDonHostedSecretsSlotId,
            args.clfPremiumFeeUsdBps,
            args.clfCallbackGasLimit,
            args.requestCLFMessageReportJsCodeHash,
            args.requestOperatorRegistrationJsCodeHash,
        ],
        log: true,
        autoMine: true,
        maxFeePerGas,
        maxPriorityFeePerGas,
    })) as Deployment;

    log(`Deployed at: ${deployment.address}`, "deployVerifier", name);
    updateEnvVariable(`CONCERO_VERIFIER_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployVerifier;
deployVerifier.tags = ["ConceroVerifier"];
