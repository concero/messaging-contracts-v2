import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { DEPLOY_CONFIG_TESTNET, conceroNetworks } from "../constants";
import { IProxyType } from "../types/deploymentVariables";
import { getFallbackClients, getViemAccount, log, updateEnvAddress } from "../utils";

const deployProxyAdmin: (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => Promise<void> =
	async function (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) {
		const { proxyDeployer } = await hre.getNamedAccounts();
		const { deploy } = hre.deployments;
		const { name } = hre.network;
		const chain = conceroNetworks[name as keyof typeof conceroNetworks];
		const { type: networkType } = chain;

		const deployConfig = DEPLOY_CONFIG_TESTNET[name as keyof typeof DEPLOY_CONFIG_TESTNET];
		const proxyDeployerViemAccount = getViemAccount(networkType, "proxyDeployer");
		const { publicClient } = getFallbackClients(chain, proxyDeployerViemAccount);

		const nonce = await proxyDeployerViemAccount.nonceManager?.get({
			address: proxyDeployer as `0x${string}`,
			chainId: chain.chainId,
			client: publicClient,
		});
		const initialOwner = proxyDeployer;

		log("Deploying...", `deployProxyAdmin: ${proxyType}`, name);
		const deployProxyAdmin = (await deploy("ConceroProxyAdmin", {
			from: proxyDeployer,
			args: [initialOwner],
			log: true,
			autoMine: true,
			nonce,
			...deployConfig.deployArgs,
		})) as Deployment;

		log(`Deployed at: ${deployProxyAdmin.address}`, `deployProxyAdmin: ${proxyType}`, name);
		updateEnvAddress(
			`${proxyType}Admin`,
			name,
			deployProxyAdmin.address,
			`deployments.${networkType}`,
		);
	};

export { deployProxyAdmin };

deployProxyAdmin.tags = ["ConceroProxyAdmin"];
