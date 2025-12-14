import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { genericDeploy } from "./GenericDeploy";

export const deployRouter = async (hre: HardhatRuntimeEnvironment) => {
	const network = conceroNetworks[hre.network.name];
	const args = { chainSelector: network.chainSelector };

	await genericDeploy(
		{ hre, contractName: "ConceroRouter", contractPrefix: "router" },
		args.chainSelector,
	);
};
