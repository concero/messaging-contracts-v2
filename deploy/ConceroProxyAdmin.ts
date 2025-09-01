import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks, DEPLOY_CONFIG_TESTNET } from "../constants";
import { IProxyType } from "../types/deploymentVariables";
import { getGasParameters, getWallet, log, updateEnvAddress } from "../utils";

const deployProxyAdmin: (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => Promise<void> =
	async function (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) {
		const { proxyDeployer } = await hre.getNamedAccounts();
		const { deploy } = hre.deployments;
		const { name } = hre.network;
		const networkType = conceroNetworks[name].type;

		const initialOwner = getWallet(networkType, "proxyDeployer", "address");

		const deployConfig = DEPLOY_CONFIG_TESTNET[name as keyof typeof DEPLOY_CONFIG_TESTNET];

		log("Deploying...", `deployProxyAdmin: ${proxyType}`, name);
		const deployProxyAdmin = (await deploy("ConceroProxyAdmin", {
			from: proxyDeployer,
			args: [initialOwner],
			log: true,
			autoMine: true,
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
