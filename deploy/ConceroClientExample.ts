import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { EnvFileName } from "../types/deploymentVariables";
import {
	genericDeploy,
	getEnvFileName,
	getEnvVar,
	getNetworkEnvKey,
	updateEnvVariable,
} from "../utils";

type DeployArgs = {
	conceroRouter: string;
	chainSelector: string;
};

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => Promise<void>;

export const deployConceroClientExample: DeploymentFunction = async (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
): Promise<void> => {
	const { name } = hre.network;
	const chain = conceroNetworks[name as keyof typeof conceroNetworks];

	const defaultArgs = {
		conceroRouter: getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(name)}`),
		relayerLib: getEnvVar(`CONCERO_RELAYER_LIB_PROXY_${getNetworkEnvKey(name)}`),
		validatorLib: getEnvVar(`CONCERO_CRE_VALIDATOR_LIB_PROXY_${getNetworkEnvKey(name)}`),
		chainSelector: chain.chainSelector,
	};

	const args = {
		...defaultArgs,
		...overrideArgs,
	};

	const deployment = await genericDeploy(
		{
			hre,
			contractName: "ConceroClientExample",
		},
		args.conceroRouter,
		args.relayerLib,
		args.validatorLib,
	);

	updateEnvVariable(
		`CONCERO_CLIENT_EXAMPLE_${getNetworkEnvKey(deployment.chainName)}`,
		deployment.address,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
	);
};
