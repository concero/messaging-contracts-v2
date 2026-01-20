import { genericDeploy } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { getEnvFileName, updateEnvAddress } from "../utils";

export const deployRouter = async (hre: HardhatRuntimeEnvironment) => {
	const network = conceroNetworks[hre.network.name];
	const args = { chainSelector: network.chainSelector };

	const deployment = await genericDeploy(
		{ hre, contractName: "ConceroRouter" },
		args.chainSelector,
	);

	updateEnvAddress(
		"router",
		deployment.address,
		getEnvFileName(`deployments.${deployment.chain.type}`),
		deployment.chain.name,
	);
};
