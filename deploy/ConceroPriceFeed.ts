import { HardhatRuntimeEnvironment } from "hardhat/types";

import { DEPLOY_CONFIG_TESTNET, conceroNetworks } from "../constants";
import { EnvFileName } from "../types/deploymentVariables";
import { genericDeploy, getEnvFileName, getNetworkEnvKey, updateEnvVariable } from "../utils";

type DeployArgs = {
	chainSelector: bigint;
	feedUpdater: string;
};

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => Promise<void>;

export const deployPriceFeed: DeploymentFunction = async (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => {
	const { name } = hre.network;
	const chain = conceroNetworks[name as keyof typeof conceroNetworks];

	const defaultArgs: DeployArgs = {
		chainSelector: chain.chainSelector,
		feedUpdater: process.env.FEED_UPDATER_ADDRESS!,
	};

	const args: DeployArgs = {
		...defaultArgs,
		...overrideArgs,
	};

	let gasLimit = 0;
	const config = DEPLOY_CONFIG_TESTNET[name];
	if (config?.priceFeed) {
		gasLimit = config.priceFeed.gasLimit;
	}

	const deployment = await genericDeploy(
		{
			hre,
			contractName: "ConceroPriceFeed",
			txParams: {
				gasLimit: BigInt(gasLimit),
			},
		},
		args.chainSelector,
		args.feedUpdater,
	);

	updateEnvVariable(
		`CONCERO_PRICE_FEED_${getNetworkEnvKey(deployment.chainName)}`,
		deployment.address,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
	);
};
