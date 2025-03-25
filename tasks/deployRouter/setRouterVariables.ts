import { HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum, conceroNetworks } from "../../constants";
import { testnetNetworks } from "../../constants/conceroNetworks";
import { ConceroNetwork, ConceroNetworkNames } from "../../types/ConceroNetwork";
import { getEnvAddress, getFallbackClients, getWallet, log } from "../../utils";

async function setAllowedOperators(hre: HardhatRuntimeEnvironment, network: ConceroNetwork) {
	const { abi: conceroRouterAbi } = await import(
		"../../../v2-operators/src/abi/ConceroRouter.json"
	);

	const { publicClient, walletClient, account } = getFallbackClients(network);

	const operatorAddress = getWallet(network.type, "operator", "address");
	const [conceroRouter] = getEnvAddress("routerProxy", network.name);

	const { request: registerOperatorRequest } = await publicClient.simulateContract({
		address: conceroRouter,
		abi: conceroRouterAbi,
		functionName: "registerOperator",
		account,
		args: [operatorAddress],
	});

	const registerHash = await walletClient.writeContract(registerOperatorRequest);
	log(
		`Operator registered with hash: ${registerHash}`,
		"setConceroRouterVariables",
		network.name,
	);
}

async function setSupportedChains(network: ConceroNetwork) {
	const { abi: conceroRouterAbi } = await import(
		"../../../v2-operators/src/abi/ConceroRouter.json"
	);
	const { publicClient, walletClient } = getFallbackClients(network);
	const [conceroRouterAddress] = getEnvAddress(ProxyEnum.routerProxy, network.name);

	for (const chainKey in testnetNetworks) {
		const dstChain = testnetNetworks[chainKey];
		if (dstChain.name === network.name) continue;

		const currentIsSupportedChain = (await publicClient.readContract({
			address: conceroRouterAddress,
			abi: conceroRouterAbi,
			functionName: "isChainSupported",
			args: [dstChain.chainSelector],
		})) as boolean;

		if (currentIsSupportedChain === true) {
			log(`[Skip]`, "isChainSupported", network.name);
			continue;
		}

		const setIsChainSupportedRequest = (
			await publicClient.simulateContract({
				account: walletClient.account,
				address: conceroRouterAddress,
				abi: conceroRouterAbi,
				functionName: "setIsChainSupported",
				args: [dstChain.chainSelector, true],
			})
		).request;
		const setIsChainSupportedHash = await walletClient.writeContract(
			setIsChainSupportedRequest,
		);
		const setIsChainSupportedStatus = (
			await publicClient.waitForTransactionReceipt({
				hash: setIsChainSupportedHash,
			})
		).status;

		if (setIsChainSupportedStatus === "success") {
			log(`added new chain: ${dstChain.name}`, "setIsChainSupported", network.name);
		} else {
			throw new Error(`set chain reverted ${setIsChainSupportedHash}`);
		}
	}
}

export async function setRouterVariables(hre: HardhatRuntimeEnvironment) {
	const { live, name } = hre.network;
	const network = conceroNetworks[name as ConceroNetworkNames];
	await setAllowedOperators(hre, network);
	await setSupportedChains(network);
}
