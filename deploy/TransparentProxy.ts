import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Hex } from "viem";

import { DEPLOY_CONFIG_TESTNET, ProxyEnum } from "../constants";
import { EnvFileName, EnvPrefixes, IProxyType } from "../types/deploymentVariables";
import {
	IDeployResult,
	extractProxyAdminAddress,
	genericDeploy,
	getEnvAddress,
	getEnvFileName,
	log,
	updateEnvAddress,
} from "../utils";

export const deployTransparentProxy = async (
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
	callData?: Hex,
): Promise<IDeployResult> => {
	const { name } = hre.network;
	const [deployer] = await hre.ethers.getSigners();

	let implementationKey: keyof EnvPrefixes;
	if (proxyType === ProxyEnum.routerProxy) {
		implementationKey = "router";
	} else if (proxyType === ProxyEnum.verifierProxy) {
		implementationKey = "verifier";
	} else if (proxyType === ProxyEnum.priceFeedProxy) {
		implementationKey = "priceFeed";
	} else if (proxyType === ProxyEnum.creValidatorLibProxy) {
		implementationKey = "creValidatorLib";
	} else if (proxyType === ProxyEnum.relayerLibProxy) {
		implementationKey = "relayerLib";
	} else {
		throw new Error(`Proxy type ${proxyType} not found`);
	}

	const [initialImplementation] = getEnvAddress(implementationKey, name);

	let gasLimit = 0;
	const config = DEPLOY_CONFIG_TESTNET[name];
	if (config?.proxy) {
		gasLimit = config.proxy.gasLimit;
	}

	const deployment = await genericDeploy(
		{
			hre,
			contractName: "TransparentUpgradeableProxy",
			txParams: {
				gasLimit: BigInt(gasLimit),
			},
		},
		initialImplementation,
		deployer.address,
		callData ?? "0x",
	);

	updateEnvAddress(
		proxyType,
		deployment.address,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
		deployment.chainName,
	);

	const proxyAdminAddress = extractProxyAdminAddress(deployment.receipt);

	log(
		`Deployed at: ${proxyAdminAddress}. initialOwner: ${deployer.address}`,
		`deployProxyAdmin: ${proxyType}`,
		deployment.chainName,
	);

	updateEnvAddress(
		`${proxyType}Admin`,
		proxyAdminAddress,
		getEnvFileName(`deployments.${deployment.chainType}` as EnvFileName),
		deployment.chainName,
	);

	return deployment;
};
