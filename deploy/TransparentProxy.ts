import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Hex } from "viem";

import { genericDeploy } from "@concero/contract-utils";

import { DEPLOY_CONFIG_TESTNET, ProxyEnum, conceroNetworks } from "../constants";
import { EnvFileName, EnvPrefixes, IProxyType } from "../types/deploymentVariables";
import { getEnvAddress, log, updateEnvAddress } from "../utils";

export const deployTransparentProxy: (
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
	callData?: Hex,
) => Promise<void> = async (
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
	callData?: Hex,
) => {
	const { name } = hre.network;
	const [deployer] = await hre.ethers.getSigners();

	const chain = conceroNetworks[name as keyof typeof conceroNetworks];
	const { type: networkType } = chain;

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
		deployment.chain.name,
		deployment.address,
		`deployments.${deployment.chain.type}` as EnvFileName,
	);

	log(
		`Deployed at: ${deployment.proxyAdminAddress}. initialOwner: ${deployer.address}`,
		`deployProxyAdmin: ${proxyType}`,
		name,
	);

	updateEnvAddress(`${proxyType}Admin`, name, deployment.proxyAdminAddress as Hex, `deployments.${networkType}`);
};
