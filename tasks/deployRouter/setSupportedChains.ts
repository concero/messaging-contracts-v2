import { ConceroNetwork } from "@concero/contract-utils";
import { testnetNetworks } from "@concero/v2-networks";

import { ProxyEnum } from "../../constants";
import { getEnvAddress, getFallbackClients, log } from "../../utils";

export async function setSupportedChains(network: ConceroNetwork) {
	const { abi: conceroRouterAbi } = await import(
		"../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);
	const { publicClient, walletClient } = getFallbackClients(network);
	const [conceroRouterAddress] = getEnvAddress(ProxyEnum.routerProxy, network.name);
	const chainSelectorsToSet = [];

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
			log(`[Skip] ${dstChain.name}`, "isChainSupported", network.name);
			continue;
		}

		chainSelectorsToSet.push(dstChain.chainSelector);
	}

	if (!chainSelectorsToSet.length) {
		log("no new networks to add", "setSupportedChains");
		return;
	}

	try {
		const setIsChainSupportedRequest = (
			await publicClient.simulateContract({
				account: walletClient.account,
				address: conceroRouterAddress,
				abi: conceroRouterAbi,
				functionName: "setSupportedChains",
				args: [chainSelectorsToSet, chainSelectorsToSet.map(() => true)],
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
			log(
				`added new chains: ${chainSelectorsToSet.length}`,
				"setSupportedChains",
				network.name,
			);
		} else {
			throw new Error(`set chain reverted ${setIsChainSupportedHash}`);
		}
	} catch (err) {
		log(`Error setting supported chains: ${err}`, "setSupportedChains", network.name);
	}
}
