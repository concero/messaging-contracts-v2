import { task } from "hardhat/config";

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { PrivateKeyAccount } from "viem";

import {
	DEPLOY_CONFIG_TESTNET,
	ProxyEnum,
	conceroNetworks,
	getViemReceiptConfig,
} from "../../constants";
import { EnvPrefixes, IProxyType } from "../../types/deploymentVariables";
import { err, getEnvAddress, getFallbackClients, getViemAccount, log } from "../../utils";
import { getTrezorDeployEnabled } from "../../utils/getTrezorDeployEnabled";
import { ethersSignerCallContract } from "./ethersSignerCallContract";

export async function upgradeProxyImplementation(
	hre: HardhatRuntimeEnvironment,
	proxyType: IProxyType,
	shouldPause: boolean,
) {
	const { name: chainName } = hre.network;
	const { viemChain, type } = conceroNetworks[chainName as keyof typeof conceroNetworks];

	let implementationKey: keyof EnvPrefixes;

	if (shouldPause) {
		implementationKey = "pause";
	} else if (proxyType === ProxyEnum.routerProxy) {
		implementationKey = "router";
	} else if (proxyType === ProxyEnum.verifierProxy) {
		implementationKey = "verifier";
	} else if (proxyType === ProxyEnum.priceFeedProxy) {
		implementationKey = "priceFeed";
	} else if (proxyType === ProxyEnum.creValidatorLibProxy) {
		implementationKey = "creValidatorLib";
	} else {
		err(`Proxy type ${proxyType} not found`, "upgradeProxyImplementation", chainName);
		return;
	}

	const { abi: proxyAdminAbi } = hre.artifacts.readArtifactSync("ProxyAdmin");

	let viemAccount: PrivateKeyAccount;
	if (proxyType === ProxyEnum.priceFeedProxy) {
		viemAccount = getViemAccount(type, "priceFeedProxyDeployer");
	} else {
		viemAccount = getViemAccount(type, "proxyDeployer");
	}

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

	let gasLimit = 0;
	const config = DEPLOY_CONFIG_TESTNET[chainName];
	if (config?.priceFeed) {
		gasLimit = config.priceFeed.gasLimit;
	}

	const functionArgs = [conceroProxy, implementation, "0x"];

	let txHash;

	if (getTrezorDeployEnabled()) {
		txHash = await ethersSignerCallContract(
			hre,
			proxyAdmin,
			proxyAdminAbi,
			"upgradeAndCall",
			...functionArgs,
		);
	} else {
		txHash = await walletClient.writeContract({
			address: proxyAdmin,
			abi: proxyAdminAbi,
			functionName: "upgradeAndCall",
			account: viemAccount,
			args: functionArgs,
			chain: viemChain,
			...(gasLimit ? { gas: gasLimit } : {}),
		});
	}

	const receipt = await publicClient.waitForTransactionReceipt({
		...getViemReceiptConfig(conceroNetworks[chainName]),
		hash: txHash,
	});

	log(
		`Upgraded via ${proxyAdminAlias}: ${conceroProxyAlias}.implementation -> ${implementationAlias}, hash: ${receipt.transactionHash}`,
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
