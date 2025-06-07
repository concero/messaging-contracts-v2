import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks, writeContractConfig } from "../constants";
import { IProxyType } from "../types/deploymentVariables";
import { getGasParameters, getWallet, log, updateEnvAddress } from "../utils";

const deployProxyAdmin: (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) => Promise<void> =
	async function (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) {
		const { proxyDeployer } = await hre.getNamedAccounts();
		const { deploy } = hre.deployments;
		const { name } = hre.network;
		const networkType = conceroNetworks[name].type;

		const initialOwner = getWallet(networkType, "proxyDeployer", "address");
		const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(
			conceroNetworks[name],
		);

		// log("Deploying...", `deployProxyAdmin: ${proxyType}`, name);
		const deployProxyAdmin = (await deploy("ConceroProxyAdmin", {
			from: proxyDeployer,
			args: [initialOwner],
			log: true,
			autoMine: true,
			skipIfAlreadyDeployed: false,
			// maxFeePerGas,
			// maxPriorityFeePerGas,
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
