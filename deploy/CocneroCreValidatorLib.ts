import { getNetworkEnvKey } from "@concero/contract-utils";
import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar, log, updateEnvVariable } from "../utils";

type DeployArgs = {
	conceroRouter: string;
	chainSelector: string;
};

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => Promise<Deployment>;

const deployConceroCreValidatorLib: DeploymentFunction = async function (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
): Promise<Deployment> {
	const { deployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
	const { name } = hre.network;
	const chain = conceroNetworks[name as ConceroNetworkNames];
	const { type: networkType } = chain;

	const defaultArgs = {
		// conceroRouter: getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(name)}`),
		// relayerLib: getEnvVar(`CONCERO_RELAYER_LIB_${getNetworkEnvKey(name)}`),
		// chainSelector: chain.chainSelector,
	};

	const args = {
		...defaultArgs,
		...overrideArgs,
	};

	const deployment = await deploy("CreValidatorLib", {
		from: deployer,
		args: [],
		log: true,
		autoMine: true,
	});

	await hre.tenderly.verify({
		name: "CreValidatorLib",
		address: deployment.address,
	});

	log(`Deployed at: ${deployment.address}`, "CreValidatorLib", name);
	updateEnvVariable(
		`CONCERO_CRE_VALIDATOR_LIB_${getNetworkEnvKey(name)}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

deployConceroCreValidatorLib.tags = ["CreValidatorLib"];

export { deployConceroCreValidatorLib };
export default deployConceroCreValidatorLib;
