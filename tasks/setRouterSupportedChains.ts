import { WalletClient } from "viem";

import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";
import { getEnvAddress, getFallbackClients, log } from "../utils";

export async function setRouterSupportedChains(
	conceroRouterAddress: string,
	walletClient: WalletClient,
	{ chainSelectors = [1], supportedStates = [true] } = {},
) {
	const { abi: conceroRouterAbi } = await import(
		"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	const txHash = await walletClient.writeContract({
		address: conceroRouterAddress,
		abi: conceroRouterAbi,
		functionName: "setSupportedChains",
		args: [
			// chainSelectors array
			chainSelectors,
			// isSupported array
			supportedStates,
		],
		account: walletClient.account,
	});
	log(`Transaction hash: ${txHash}`, "setRouterSupportedChains");
}

task("set-router-supportedchains", "Set supported chains for the router").setAction(
	async (_, hre) => {
		const [router] = getEnvAddress("routerProxy", hre.network.name);

		const conceroNetwork = conceroNetworks[hre.network.name];

		const { walletClient } = getFallbackClients(conceroNetwork);

		await setRouterSupportedChains(router, walletClient, {
			chainSelectors: [1],
			supportedStates: [true],
		});
	},
);
