import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployment } from "hardhat-deploy/types";
import { getEnvVar, getHashSum, updateEnvVariable, getGasParameters, log } from "../utils";
import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { resolve } from "path";

const requestReportJsCode = resolve(__dirname, "../../clf/dist/requestReport.min.js");
const requestOperatorRegistrationJsCode = resolve(__dirname, "../../clf/dist/requestOperatorRegistration.min.js");

type DeployArgs = {
    chainSelector: string;
    usdc: string;
    clfRouter: string;
    clfDonId: string;
    clfSubscriptionId: string;
    clfDonHostedSecretsVersion: string;
    clfDonHostedSecretsSlotId: string;
    clfPremiumFeeUsdBps: string;
    clfCallbackGasLimit: bigint;
    requestCLFMessageReportJsCodeHash: string;
    requestOperatorRegistrationJsCodeHash: string;
};

type DeploymentFunction = (hre: HardhatRuntimeEnvironment, overrideArgs?: Partial<DeployArgs>) => Promise<Deployment>;

const deployVerifier: DeploymentFunction = async function (
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
        clfRouter: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
        clfDonId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
        clfSubscriptionId: getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`),
        clfDonHostedSecretsVersion: getEnvVar(`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`),
        clfDonHostedSecretsSlotId: "0",
        clfPremiumFeeUsdBps: getEnvVar(`CLF_PREMIUM_FEE_USD_BPS_${networkEnvKeys[name]}`),
        clfCallbackGasLimit: 100_000n,
        requestCLFMessageReportJsCodeHash: getHashSum(requestReportJsCode),
        requestOperatorRegistrationJsCodeHash: getHashSum(requestOperatorRegistrationJsCode),
    };

    const args: DeployArgs = {
        ...defaultArgs,
        ...overrideArgs,
    };

    const deployment = await deploy("ConceroVerifier", {
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
        skipIfAlreadyDeployed: true,
        maxFeePerGas,
        maxPriorityFeePerGas,
    });

    log(`Deployed at: ${deployment.address}`, "deployVerifier", name);
    updateEnvVariable(`CONCERO_VERIFIER_${networkEnvKeys[name]}`, deployment.address, `deployments.${networkType}`);

    return deployment;
};

export default deployVerifier;
deployVerifier.tags = ["ConceroVerifier"];
