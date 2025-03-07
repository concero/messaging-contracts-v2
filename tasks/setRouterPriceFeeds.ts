import { WalletClient, zeroHash } from "viem";

import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";
import {
	Namespaces as routerNamespaces,
	PriceFeedSlots as routerPriceFeedSlots,
} from "../constants/storage/ConceroRouterStorage";
import { getEnvAddress, getFallbackClients, log } from "../utils";

export async function setRouterPriceFeeds(
	conceroRouterAddress: string,
	walletClient: WalletClient,
	{
		chainSelector = 1n,
		nativeUsdRate = 2000e18,
		nativeNativeRate = 1e18,
		lastGasPrice = 1_000_000n,
	} = {},
) {
	const { abi: conceroRouterAbi } = await import(
		"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	const toBytes32 = (value: BigInt) => `0x${value.toString(16).padStart(64, "0")}`;

	const txHash = await walletClient.writeContract({
		address: conceroRouterAddress,
		abi: conceroRouterAbi,
		functionName: "setStorageBulk",
		args: [
			// namespaces array
			[routerNamespaces.PRICEFEED, routerNamespaces.PRICEFEED, routerNamespaces.PRICEFEED],
			// offsets array
			[
				BigInt(routerPriceFeedSlots.nativeUsdRate),
				BigInt(routerPriceFeedSlots.lastGasPrices),
				BigInt(routerPriceFeedSlots.nativeNativeRates),
			],
			// mappingKeys array
			[zeroHash, toBytes32(chainSelector), toBytes32(chainSelector)],
			// values array
			[BigInt(nativeUsdRate), lastGasPrice, nativeNativeRate],
		],
		account: walletClient.account,
	});
	log(`Transaction hash: ${txHash}`, "setVerifierPriceFeeds");
}

task("set-router-pricefeeds", "Set price feeds for the router").setAction(async (_, hre) => {
	const [router] = getEnvAddress("routerProxy", hre.network.name);

	const conceroNetwork = conceroNetworks[hre.network.name];

	const { walletClient } = getFallbackClients(conceroNetwork);

	await setRouterPriceFeeds(router, walletClient, {
		chainSelector: conceroNetwork.chainSelector,
		nativeUsdRate: 2000e18,
		nativeNativeRate: 1e18,
		lastGasPrice: 1_000_000n,
	});
});
