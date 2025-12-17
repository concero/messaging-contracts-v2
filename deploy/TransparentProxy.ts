import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Hex } from "viem";

import { ADMIN_SLOT, DEPLOY_CONFIG_TESTNET, ProxyEnum, conceroNetworks } from "../constants";
import { EnvPrefixes, IProxyType } from "../types/deploymentVariables";
import { getEnvAddress, getFallbackClients, getViemAccount, log, updateEnvAddress } from "../utils";
import { genericDeploy } from "./GenericDeploy";

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

	await genericDeploy(
		{
			hre,
			contractName: "TransparentUpgradeableProxy",
			contractPrefix: proxyType,
			txParams: {
				gasLimit: BigInt(gasLimit),
			},
		},
		initialImplementation,
		deployer.address,
		callData ?? "0x",
	);

	const [proxyAddress] = getEnvAddress(proxyType, name);
	const viemAccount = getViemAccount(networkType, "deployer");
	const { publicClient } = getFallbackClients(chain, viemAccount);

	const proxyAdminBytes = await publicClient.getStorageAt({
		address: proxyAddress as Hex,
		slot: ADMIN_SLOT as Hex,
	});

	const proxyAdminAddress = `0x${proxyAdminBytes!.slice(-40)}` as Hex;

	log(
		`Deployed at: ${proxyAdminAddress}. initialOwner: ${deployer.address}`,
		`deployProxyAdmin: ${proxyType}`,
		name,
	);

	updateEnvAddress(`${proxyType}Admin`, name, proxyAdminAddress, `deployments.${networkType}`);
};
