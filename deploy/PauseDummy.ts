import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { getNetworkEnvKey } from "@concero/contract-utils";

import { conceroNetworks } from "../constants";
import { log, updateEnvVariable } from "../utils";

const deployPauseDummy: (hre: HardhatRuntimeEnvironment) => Promise<void> = async function (
	hre: HardhatRuntimeEnvironment,
) {
	const { deployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
	const { name, live } = hre.network;
	const networkType = conceroNetworks[name].type;

	// console.log("Deploying...", "deployPauseDummy", name);

	const deployPauseDummy = (await deploy("PauseDummy", {
		from: deployer,
		args: [],
		log: true,
		autoMine: true,
	})) as Deployment;

	if (live) {
		log(`Deployed at: ${deployPauseDummy.address}`, "deployPauseDummy", name);
		updateEnvVariable(
			`CONCERO_PAUSE_${getNetworkEnvKey(name)}`,
			deployPauseDummy.address,
			`deployments.${networkType}`,
		);
	}
};

export { deployPauseDummy };

deployPauseDummy.tags = ["PauseDummy"];
