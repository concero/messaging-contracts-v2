import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { DEPLOY_CONFIG_TESTNET, ProxyEnum, conceroNetworks } from "../constants";
import { EnvPrefixes, IProxyType } from "../types/deploymentVariables";
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

	let implementationKey: keyof EnvPrefixes;
	if (proxyType === ProxyEnum.routerProxy) {
		implementationKey = "router";
	} else if (proxyType === ProxyEnum.verifierProxy) {
		implementationKey = "verifier";
	} else if (proxyType === ProxyEnum.priceFeedProxy) {
		implementationKey = "priceFeed";
	} else {
		throw new Error(`Proxy type ${proxyType} not found`);
	}

	const [initialImplementation, initialImplementationAlias] = getEnvAddress(
		implementationKey,
		name,
	);
	const [proxyAdmin, proxyAdminAlias] = getEnvAddress(`${proxyType}Admin`, name);

	const deployConfig = DEPLOY_CONFIG_TESTNET[name as keyof typeof DEPLOY_CONFIG_TESTNET];

	log("Deploying...", `deployTransparentProxy:${proxyType}`, name);
	const conceroProxyDeployment = (await deploy("TransparentUpgradeableProxy", {
		from: proxyDeployer,
		args: [initialImplementation, proxyAdmin, "0x"],
		log: true,
		autoMine: true,
		...deployConfig.deployArgs,
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
