import { HardhatRuntimeEnvironment } from "hardhat/types";

import { genericDeploy } from "@concero/contract-utils";

import { conceroNetworks } from "../constants";
import { updateEnvAddress } from "../utils";
import { EnvFileName } from "../types/deploymentVariables";

export const deployRouter = async (hre: HardhatRuntimeEnvironment) => {
	const network = conceroNetworks[hre.network.name];
	const args = { chainSelector: network.chainSelector };

	const deployment = await genericDeploy(
		{ hre, contractName: "ConceroRouter" },
		args.chainSelector,
	);

	updateEnvAddress(
		"router",
		deployment.chain.name,
		deployment.address,
		`deployments.${deployment.chain.type}` as EnvFileName,
	);
};
