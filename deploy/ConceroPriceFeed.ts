import { getNetworkEnvKey } from "@concero/contract-utils";
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
	const { deployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
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

	const deployConfig = DEPLOY_CONFIG_TESTNET[name as keyof typeof DEPLOY_CONFIG_TESTNET];
	const deployerViemAccount = getViemAccount(networkType, "deployer");
	const { publicClient } = getFallbackClients(chain, deployerViemAccount);

	const nonce = await deployerViemAccount.nonceManager?.get({
		address: deployer as `0x${string}`,
		chainId: chain.chainId,
		client: publicClient,
	});

	const deployment = await deploy("ConceroPriceFeed", {
		from: deployer,
		args: [args.chainSelector, args.feedUpdater],
		log: true,
		autoMine: true,
		nonce,
		...deployConfig.deployArgs,
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
