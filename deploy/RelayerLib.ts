import { getNetworkEnvKey } from "@concero/contract-utils";
import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar, log, updateEnvVariable } from "../utils";

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: any,
) => Promise<Deployment>;

const deployRelayerLib: DeploymentFunction = async function (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: any,
): Promise<Deployment> {
	const { deployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
	const { name } = hre.network;
	const chain = conceroNetworks[name as ConceroNetworkNames];
	const { type: networkType } = chain;

	const defaultArgs = {
		conceroRouter: getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(name)}`),
		conceroPriceFeed: getEnvVar(`CONCERO_PRICE_FEED_PROXY_${getNetworkEnvKey(name)}`),
		chainSelector: chain.chainSelector,
	};

	const args = { ...defaultArgs, ...overrideArgs };

	const deployment = await deploy("RelayerLib", {
		from: deployer,
		args: [args.chainSelector, args.conceroPriceFeed, args.conceroRouter],
		log: true,
		autoMine: true,
	});

	log(`Deployed at: ${deployment.address}`, "RelayerLib", name);
	updateEnvVariable(
		`CONCERO_RELAYER_LIB_${getNetworkEnvKey(name)}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

deployRelayerLib.tags = ["RelayerLib"];

export { deployRelayerLib };
export default deployRelayerLib;
