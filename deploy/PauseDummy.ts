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

	console.log("Deploying...", "deployPauseDummy", name);

	const deployment = await deploy("PauseDummy", {
		from: deployer,
		args: [],
		log: true,
		autoMine: true,
	});

	if (live) {
		log(`Deployed at: ${deployment.address}`, "deployPauseDummy", name);
		updateEnvVariable(
			`CONCERO_PAUSE_${getNetworkEnvKey(name)}`,
			deployment.address,
			`deployments.${networkType}`,
		);
	}

	return deployment
};

export { deployPauseDummy };

deployPauseDummy.tags = ["PauseDummy"];
