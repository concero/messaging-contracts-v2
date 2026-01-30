import { HardhatRuntimeEnvironment } from "hardhat/types";

import { CLF_DON_HOSTED_SECRETS_SLOT, conceroNetworks } from "../constants";
import { EnvFileName } from "../types/deploymentVariables";
import {
	genericDeploy,
	getEnvFileName,
	getEnvVar,
	getHashSum,
	getNetworkEnvKey,
	updateEnvVariable,
} from "../utils";
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
) => Promise<IDeployResult>;

export const deployVerifier: DeploymentFunction = async (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
): Promise<IDeployResult> => {
	const { name } = hre.network;
	const chain = conceroNetworks[name as keyof typeof conceroNetworks];

	const defaultArgs: DeployArgs = {
		chainSelector: chain.chainSelector,
		usdc: getEnvVar(`USDC_${getNetworkEnvKey(name)}`) as string,
		conceroPriceFeed: getEnvVar(`CONCERO_PRICE_FEED_PROXY_${getNetworkEnvKey(name)}`) as string,
		clfParams: {
			router: getEnvVar(`CLF_ROUTER_${getNetworkEnvKey(name)}`) as string,
			donId: getEnvVar(`CLF_DONID_${getNetworkEnvKey(name)}`) as string,
			subscriptionId: getEnvVar(`CLF_SUBID_${getNetworkEnvKey(name)}`) as string,
			donHostedSecretsVersion: getEnvVar(
				`CLF_DON_SECRETS_VERSION_${getNetworkEnvKey(name)}`,
			) as string,
			donHostedSecretsSlotId: CLF_DON_HOSTED_SECRETS_SLOT,
			premiumFeeUsdBps: getEnvVar(
				`CLF_PREMIUM_FEE_USD_BPS_${getNetworkEnvKey(name)}`,
			) as string,
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

	const deployment = await genericDeploy(
		{
			hre,
			contractName: "ConceroVerifier",
		},
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
	);

	updateEnvVariable(
		`CONCERO_VERIFIER_${getNetworkEnvKey(deployment.chainName)}`,
		deployment.address,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
	);

	return deployment;
};
