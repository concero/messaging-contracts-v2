import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { resolve } from "path";

import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar, getGasParameters, getHashSum, log, updateEnvVariable } from "../utils";

const requestReportJsCode = resolve(__dirname, "../../clf/dist/requestReport.min.js");
const requestOperatorRegistrationJsCode = resolve(
	__dirname,
	"../../clf/dist/requestOperatorRegistration.min.js",
);

type DeployArgs = {
	chainSelector: string;
	usdc: string;
	clfParams: {
		router: string;
		donId: string;
		subscriptionId: string;
		donHostedSecretsVersion: string;
		donHostedSecretsSlotId: string;
		premiumFeeUsdBps: string;
		callbackGasLimit: bigint;
		requestCLFMessageReportJsCodeHash: string;
		requestOperatorRegistrationJsCodeHash: string;
	};
};

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => Promise<Deployment>;

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
		clfParams: {
			router: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
			donId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
			subscriptionId: getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`),
			donHostedSecretsVersion: getEnvVar(`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`),
			donHostedSecretsSlotId: "0",
			premiumFeeUsdBps: getEnvVar(`CLF_PREMIUM_FEE_USD_BPS_${networkEnvKeys[name]}`),
			callbackGasLimit: 100_000n,
			requestCLFMessageReportJsCodeHash: getHashSum(requestReportJsCode),
			requestOperatorRegistrationJsCodeHash: getHashSum(requestOperatorRegistrationJsCode),
		},
	};

	const args: DeployArgs = {
		...defaultArgs,
		...overrideArgs,
		clfParams: {
			...defaultArgs.clfParams,
			...(overrideArgs?.clfParams || {}),
		},
	};

	const deployment = await deploy("ConceroVerifier", {
		from: deployer,
		args: [
			args.chainSelector,
			args.usdc,
			[
				args.clfParams.router,
				args.clfParams.donId,
				args.clfParams.subscriptionId,
				args.clfParams.donHostedSecretsVersion,
				args.clfParams.donHostedSecretsSlotId,
				args.clfParams.premiumFeeUsdBps,
				args.clfParams.callbackGasLimit,
				args.clfParams.requestCLFMessageReportJsCodeHash,
				args.clfParams.requestOperatorRegistrationJsCodeHash,
			],
		],
		log: true,
		autoMine: true,
		skipIfAlreadyDeployed: true,
		maxFeePerGas,
		maxPriorityFeePerGas,
	});

	log(`Deployed at: ${deployment.address}`, "deployVerifier", name);
	updateEnvVariable(
		`CONCERO_VERIFIER_${networkEnvKeys[name]}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

export default deployVerifier;
deployVerifier.tags = ["ConceroVerifier"];
