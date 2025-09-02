import { getNetworkEnvKey } from "@concero/contract-utils";
import { hardhatDeployWrapper } from "@concero/contract-utils";
import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { DEPLOY_CONFIG_TESTNET, conceroNetworks } from "../constants";
import { getFallbackClients, getViemAccount, log, updateEnvVariable } from "../utils";

type DeployArgs = {
	chainSelector: bigint;
	feedUpdater: string;
};

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => Promise<Deployment>;

const deployPriceFeed: DeploymentFunction = async function (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
): Promise<Deployment> {
	const { name } = hre.network;

	const chain = conceroNetworks[name as keyof typeof conceroNetworks];
	const { type: networkType } = chain;

	const defaultArgs: DeployArgs = {
		chainSelector: chain.chainSelector,
		feedUpdater: process.env.FEED_UPDATER_ADDRESS!,
	};

	const args: DeployArgs = {
		...defaultArgs,
		...overrideArgs,
	};

	const deployerViemAccount = getViemAccount(networkType, "deployer");
	const { publicClient } = getFallbackClients(chain, deployerViemAccount);

	let gasLimit = 0;
	const config = DEPLOY_CONFIG_TESTNET[name];
	if (config?.priceFeed) {
		gasLimit = config.priceFeed.gasLimit;
	}

	const deployment = await hardhatDeployWrapper("ConceroPriceFeed", {
		hre,
		args: [args.chainSelector, args.feedUpdater],
		publicClient,
		gasLimit,
		log: true,
	});

	log(`Deployed at: ${deployment.address}`, "deployPriceFeed", name);
	updateEnvVariable(
		`CONCERO_PRICE_FEED_${getNetworkEnvKey(name)}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

deployPriceFeed.tags = ["ConceroPriceFeed"];

export default deployPriceFeed;
export { deployPriceFeed };
