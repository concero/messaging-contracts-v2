import { hardhatDeployWrapper } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { DEPLOY_CONFIG_TESTNET, conceroNetworks } from "../constants";
import { IProxyType } from "../types/deploymentVariables";
import { getFallbackClients, getViemAccount, log, updateEnvAddress } from "../utils";

const deployProxyAdmin: (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => Promise<void> =
	async function (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) {
		const { name } = hre.network;
		const chain = conceroNetworks[name as keyof typeof conceroNetworks];
		const { type: networkType } = chain;

		const proxyDeployerViemAccount = getViemAccount(networkType, "proxyDeployer");

		const { publicClient } = getFallbackClients(chain, proxyDeployerViemAccount);

		const initialOwner = proxyDeployerViemAccount.address;

		let gasLimit = 0;
		const config = DEPLOY_CONFIG_TESTNET[name];
		if (config?.proxyAdmin) {
			gasLimit = config.proxyAdmin.gasLimit;
		}

		const deployProxyAdmin = await hardhatDeployWrapper("ConceroProxyAdmin", {
			hre,
			args: [initialOwner],
			publicClient,
			proxy: true,
			gasLimit,
		});

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
