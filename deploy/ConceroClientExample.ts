import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks, networkEnvKeys } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar, log, updateEnvVariable } from "../utils";

type DeployArgs = {
	conceroRouter: string;
	chainSelector: bigint;
};

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => Promise<Deployment>;

const deployConceroClientExample: DeploymentFunction = async function (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
): Promise<Deployment> {
	const { deployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
	const { name } = hre.network;
	const chain = conceroNetworks[name as ConceroNetworkNames];
	const { type: networkType } = chain;

	const defaultArgs: DeployArgs = {
		conceroRouter: getEnvVar(`CONCERO_ROUTER_${networkEnvKeys[name]}`),
		chainSelector: 1n,
	};

	const args: DeployArgs = {
		...defaultArgs,
		...overrideArgs,
	};
	// Changed from "ConceroClient" to "ConceroClientExample.sol"
	const deployment = await deploy("ConceroClientExample", {
		from: deployer,
		args: [args.conceroRouter, args.chainSelector],
		log: true,
		autoMine: true,
	});

	log(`Deployed at: ${deployment.address}`, "ConceroClientExample", name);
	updateEnvVariable(
		`CONCERO_CLIENT_EXAMPLE_${networkEnvKeys[name]}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

export { deployConceroClientExample };
deployConceroClientExample.tags = ["ConceroClientExample"];
