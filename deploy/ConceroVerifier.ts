import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { CLF_DON_HOSTED_SECRETS_SLOT, conceroNetworks, networkEnvKeys } from "../constants";
import { addCLFConsumer } from "../tasks/clf";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar, getGasParameters, getHashSum, log, updateEnvVariable } from "../utils";
import { ClfJsCodeType, getClfJsCode } from "../utils/getClfJsCode";

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
	const { name, live } = hre.network;

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
			donHostedSecretsSlotId: CLF_DON_HOSTED_SECRETS_SLOT,
			premiumFeeUsdBps: getEnvVar(`CLF_PREMIUM_FEE_USD_BPS_${networkEnvKeys[name]}`),
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
		`CONCERO_VERIFIER_${networkEnvKeys[name]}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	if (live) {
		await addCLFConsumer(
			conceroNetworks[name],
			[deployment.address],
			args.clfParams.subscriptionId,
		);
	}

	return deployment;
};

export { deployVerifier };
export default deployVerifier;
deployVerifier.tags = ["ConceroVerifier"];
