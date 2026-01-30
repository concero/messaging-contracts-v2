import { HardhatRuntimeEnvironment } from "hardhat/types";

import { EnvFileName } from "../types/deploymentVariables";
import { IDeployResult, genericDeploy, getNetworkEnvKey, log, updateEnvVariable } from "../utils";

export const deployPauseDummy = async (hre: HardhatRuntimeEnvironment): Promise<IDeployResult> => {
	const deployment = await genericDeploy(
		{
			hre,
			contractName: "PauseDummy",
		},
		[],
	);

	if (hre.network.live) {
		updateEnvVariable(
			`CONCERO_PAUSE_${getNetworkEnvKey(deployment.chainName)}`,
			deployment.address,
			`deployments.${deployment.chainType}` as EnvFileName,
		);
	}

	return deployment;
};
