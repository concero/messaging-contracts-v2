import { hardhatDeployWrapper } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Hex } from "viem";

import { DEPLOY_CONFIG_TESTNET, ProxyEnum, conceroNetworks } from "../constants";
import { EnvPrefixes, IProxyType } from "../types/deploymentVariables";
import { getEnvAddress, getFallbackClients, getViemAccount, log, updateEnvAddress } from "../utils";

const deployTransparentProxy: (
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
	callData?: Hex,
) => Promise<void> = async function (
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
	callData: Hex,
) {
	const { name } = hre.network;
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

	const [initialImplementation, initialImplementationAlias] = getEnvAddress(
		implementationKey,
		name,
	);

	const [proxyAdmin, proxyAdminAlias] = getEnvAddress(`${proxyType}Admin`, name);

	const proxyDeployerViemAccount = getViemAccount(networkType, "proxyDeployer");
	const { publicClient } = getFallbackClients(chain, proxyDeployerViemAccount);

	let gasLimit = 0;
	const config = DEPLOY_CONFIG_TESTNET[name];
	if (config?.proxy) {
		gasLimit = config.proxy.gasLimit;
	}

	const conceroProxyDeployment = await hardhatDeployWrapper("TransparentUpgradeableProxy", {
		hre,
		args: [initialImplementation, proxyAdmin, callData ?? "0x"],
		publicClient,
		proxy: true,
		gasLimit,
	});

	log(
		`Deployed at: ${conceroProxyDeployment.address}. Initial impl: ${initialImplementationAlias}, Proxy admin: ${proxyAdminAlias}`,
		`deployTransparentProxy: ${proxyType}`,
		name,
	);
	updateEnvAddress(proxyType, name, conceroProxyDeployment.address, `deployments.${networkType}`);
};

export { deployTransparentProxy };

deployTransparentProxy.tags = ["TransparentProxy"];
