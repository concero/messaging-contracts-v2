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
		try {
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
		} catch (err) {
			log(`Error setting supported chains: ${err}`, "setSupportedChains", network.name);
		}
	}
	try {
		if (!chainSelectorsToSet.length) {
			log("no new networks to add", "setSupportedChains");
			return;
		}

		const setIsChainSupportedHash = await walletClient.writeContract({
			account: walletClient.account,
			address: conceroRouterAddress,
			abi: conceroRouterAbi,
			functionName: "setSupportedChains",
			args: [chainSelectorsToSet, chainSelectorsToSet.map(() => true)],
		});
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
			log(
				`set chain reverted ${setIsChainSupportedHash}`,
				"setSupportedChains",
				network.name,
			);
		}
	} catch (error) {
		log(error.message, "setSupportedChains", network.name);
	}
}
