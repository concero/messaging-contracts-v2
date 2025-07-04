import { task } from "hardhat/config";

import { ProxyEnum, conceroNetworks, getViemReceiptConfig } from "../../constants";
import { EnvPrefixes, IProxyType } from "../../types/deploymentVariables";
import {
	err,
	formatGas,
	getEnvAddress,
	getFallbackClients,
	getViemAccount,
	log,
} from "../../utils";

export async function upgradeProxyImplementation(hre, proxyType: IProxyType, shouldPause: boolean) {
	const { name: chainName } = hre.network;
	const { viemChain, type } = conceroNetworks[chainName];

	let implementationKey: keyof EnvPrefixes;

	if (shouldPause) {
		implementationKey = "pause";
	} else if (proxyType === ProxyEnum.routerProxy) {
		implementationKey = "router";
	} else if (proxyType === ProxyEnum.verifierProxy) {
		implementationKey = "verifier";
	} else {
		err(`Proxy type ${proxyType} not found`, "upgradeProxyImplementation", chainName);
		return;
	}

	const { abi: proxyAdminAbi } = await import(
		"../../artifacts/contracts/Proxy/ConceroProxyAdmin.sol/ConceroProxyAdmin.json"
	);

	const viemAccount = getViemAccount(type, "proxyDeployer");
	const { walletClient, publicClient } = getFallbackClients(
		conceroNetworks[chainName],
		viemAccount,
	);

	const [conceroProxy, conceroProxyAlias] = getEnvAddress(proxyType, chainName);
	const [proxyAdmin, proxyAdminAlias] = getEnvAddress(`${proxyType}Admin`, chainName);
	const [newImplementation, newImplementationAlias] = getEnvAddress(implementationKey, chainName);

	const implementation = shouldPause ? getEnvAddress("pause", chainName)[0] : newImplementation;
	const implementationAlias = shouldPause
		? getEnvAddress("pause", chainName)[1]
		: newImplementationAlias;

	const txHash = await walletClient.writeContract({
		address: proxyAdmin,
		abi: proxyAdminAbi,
		functionName: "upgradeAndCall",
		account: viemAccount,
		args: [conceroProxy, implementation, "0x"],
		chain: viemChain,
		gas: 100000,
	});

	const { cumulativeGasUsed } = await publicClient.waitForTransactionReceipt({
		...getViemReceiptConfig(conceroNetworks[chainName]),
		hash: txHash,
	});

	log(
		`Upgraded via ${proxyAdminAlias}: ${conceroProxyAlias}.implementation -> ${implementationAlias}. Gas : ${formatGas(cumulativeGasUsed)}, hash: ${txHash}`,
		`setProxyImplementation : ${proxyType}`,
		chainName,
	);
}
task("upgrade-proxy-implementation", "Upgrades the proxy implementation")
	.addFlag("pause", "Pause the proxy before upgrading", false)
	.addParam("proxytype", "The type of the proxy to upgrade", undefined)
	.setAction(async taskArgs => {
		await upgradeProxyImplementation(hre, taskArgs.proxytype, taskArgs.pause);
	});
