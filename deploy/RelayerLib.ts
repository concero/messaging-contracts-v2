import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { EnvFileName } from "../types/deploymentVariables";
import {
	genericDeploy,
	getEnvFileName,
	getEnvVar,
	getNetworkEnvKey,
	updateEnvAddress,
} from "../utils";

type DeploymentFunction = (hre: HardhatRuntimeEnvironment, overrideArgs?: any) => Promise<void>;

export const deployRelayerLib: DeploymentFunction = async (
	hre: HardhatRuntimeEnvironment,
): Promise<void> => {
	const { name } = hre.network;
	const chain = conceroNetworks[name as keyof typeof conceroNetworks];

	const defaultArgs = [
		chain.chainSelector,
		getEnvVar(`CONCERO_PRICE_FEED_PROXY_${getNetworkEnvKey(name)}`),
		getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(name)}`),
	];

	const deployment = await genericDeploy({ hre, contractName: "RelayerLib" }, ...defaultArgs);

	updateEnvAddress(
		"relayerLib",
		deployment.address,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
		deployment.chainName,
	);
};
