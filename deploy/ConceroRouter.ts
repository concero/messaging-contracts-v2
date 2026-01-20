import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { EnvFileName } from "../types/deploymentVariables";
import { genericDeploy, getEnvFileName, updateEnvAddress } from "../utils";

export const deployRouter = async (hre: HardhatRuntimeEnvironment): Promise<void> => {
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
};
