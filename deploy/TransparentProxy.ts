import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { IProxyType } from "../types/deploymentVariables";
import { getEnvAddress, getGasParameters, log, updateEnvAddress } from "../utils";

const deployTransparentProxy: (
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
) => Promise<void> = async function (hre: HardhatRuntimeEnvironment, proxyType: IProxyType) {
	const { proxyDeployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
	const { name, live } = hre.network;
	const chain = conceroNetworks[name];
	const { type } = chain;

	const [initialImplementation, initialImplementationAlias] = getEnvAddress("router", name);
	const [proxyAdmin, proxyAdminAlias] = getEnvAddress(`${proxyType}Admin`, name);

	const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

	// log("Deploying...", `deployTransparentProxy:${proxyType}`, name);
	const conceroProxyDeployment = (await deploy("TransparentUpgradeableProxy", {
		from: proxyDeployer,
		args: [initialImplementation, proxyAdmin, "0x"],
		log: true,
		autoMine: true,
		maxFeePerGas,
		maxPriorityFeePerGas,
		// gasLimit: writeContractConfig.gas,
	})) as Deployment;

	log(
		`Deployed at: ${conceroProxyDeployment.address}. Initial impl: ${initialImplementationAlias}, Proxy admin: ${proxyAdminAlias}`,
		`deployTransparentProxy: ${proxyType}`,
		name,
	);
	updateEnvAddress(proxyType, name, conceroProxyDeployment.address, `deployments.${type}`);
};

export { deployTransparentProxy };

deployTransparentProxy.tags = ["TransparentProxy"];
