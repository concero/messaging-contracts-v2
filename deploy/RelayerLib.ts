import { getNetworkEnvKey } from "@concero/contract-utils";
import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { ConceroNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar } from "../utils";
import { genericDeploy } from "./GenericDeploy";

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: any,
) => Promise<Deployment>;

const deployRelayerLib: DeploymentFunction = async function (
	hre: HardhatRuntimeEnvironment,
): Promise<Deployment> {
	const { name } = hre.network;
	const chain = conceroNetworks[name as ConceroNetworkNames];

	const defaultArgs = [
		chain.chainSelector,
		getEnvVar(`CONCERO_PRICE_FEED_PROXY_${getNetworkEnvKey(name)}`),
		getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(name)}`),
	];

	await genericDeploy(
		{ hre, contractName: "RelayerLib", contractPrefix: "relayerLib" },
		...defaultArgs,
	);
};

export { deployRelayerLib };
export default deployRelayerLib;
