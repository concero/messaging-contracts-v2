import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { getNetworkEnvKey } from "@concero/contract-utils";

import { CLF_DON_HOSTED_SECRETS_SLOT, conceroNetworks } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar, getGasParameters, getHashSum, log, updateEnvVariable } from "../utils";
import { ClfJsCodeType, getClfJsCode } from "../utils/getClfJsCode";

type DeployArgs = {
	chainSelector: bigint;
	usdc: string;
	conceroPriceFeed: string;
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
	const { name, live } = hre.network;

	const chain = conceroNetworks[name as ConceroNetworkNames];
	const { type: networkType } = chain;

	const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

	const defaultArgs: DeployArgs = {
		chainSelector: chain.chainSelector,
		usdc: getEnvVar(`USDC_${getNetworkEnvKey(name)}`),
		conceroPriceFeed: getEnvVar(`CONCERO_PRICE_FEED_PROXY_${getNetworkEnvKey(name)}`),
		clfParams: {
			router: getEnvVar(`CLF_ROUTER_${getNetworkEnvKey(name)}`),
			donId: getEnvVar(`CLF_DONID_${getNetworkEnvKey(name)}`),
			subscriptionId: getEnvVar(`CLF_SUBID_${getNetworkEnvKey(name)}`),
			donHostedSecretsVersion: getEnvVar(`CLF_DON_SECRETS_VERSION_${getNetworkEnvKey(name)}`),
			donHostedSecretsSlotId: CLF_DON_HOSTED_SECRETS_SLOT,
			premiumFeeUsdBps: getEnvVar(`CLF_PREMIUM_FEE_USD_BPS_${getNetworkEnvKey(name)}`),
			callbackGasLimit: 100_000n,
			requestCLFMessageReportJsCodeHash: getHashSum(
				await getClfJsCode(ClfJsCodeType.MessageReport),
			),
			requestOperatorRegistrationJsCodeHash: getHashSum(
				await getClfJsCode(ClfJsCodeType.OperatorRegistration),
			),
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
			args.conceroPriceFeed,
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
		// maxFeePerGas,
		// maxPriorityFeePerGas,
	});

	log(`Deployed at: ${deployment.address}`, "deployVerifier", name);
	updateEnvVariable(
		`CONCERO_VERIFIER_${getNetworkEnvKey(name)}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

export { deployVerifier };

deployVerifier.tags = ["ConceroVerifier"];
