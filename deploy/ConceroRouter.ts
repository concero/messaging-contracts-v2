import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { EnvFileName } from "../types/deploymentVariables";
import { IDeployResult, genericDeploy, getEnvFileName, updateEnvAddress } from "../utils";

export const deployRouter = async (hre: HardhatRuntimeEnvironment): Promise<IDeployResult> => {
	const network = conceroNetworks[hre.network.name as keyof typeof conceroNetworks];
	const args = { chainSelector: network.chainSelector };

	const deployment = await genericDeploy(
		{ hre, contractName: "ConceroRouter" },
		args.chainSelector,
	);

	updateEnvAddress(
		"router",
		deployment.address,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
		deployment.chainName,
	);

	return deployment;
};
