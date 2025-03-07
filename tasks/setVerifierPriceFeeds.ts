import { WalletClient, zeroHash } from "viem";

import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";
import {
	Namespaces as verifierNamespaces,
	PriceFeedSlots as verifierPriceFeedSlots,
} from "../constants/storage/ConceroVerifierStorage";
import { getEnvAddress, getFallbackClients, log } from "../utils";

export async function setVerifierPriceFeeds(
	conceroVerifierAddress: string,
	walletClient: WalletClient,
	{
		chainSelector = 1n,
		nativeUsdRate = 2000e18,
		nativeNativeRate = 1e18,
		lastGasPrice = 1_000_000n,
	} = {},
) {
	const { abi: conceroVerifierAbi } = await import(
		"../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const toBytes32 = (value: BigInt) => `0x${value.toString(16).padStart(64, "0")}`;

	const txHash = await walletClient.writeContract({
		address: conceroVerifierAddress,
		abi: conceroVerifierAbi,
		functionName: "setStorageBulk",
		args: [
			// namespaces array
			[
				verifierNamespaces.PRICEFEED,
				verifierNamespaces.PRICEFEED,
				verifierNamespaces.PRICEFEED,
			],
			// offsets array
			[
				BigInt(verifierPriceFeedSlots.nativeUsdRate),
				BigInt(verifierPriceFeedSlots.lastGasPrices),
				BigInt(verifierPriceFeedSlots.nativeNativeRates),
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

task("set-verifier-pricefeeds", "Set price feeds for the verifier").setAction(async (_, hre) => {
	const [verifier] = getEnvAddress("verifierProxy", hre.network.name);

	const conceroNetwork = conceroNetworks[hre.network.name];

	const { walletClient } = getFallbackClients(conceroNetwork);

	await setVerifierPriceFeeds(verifier, walletClient, {
		chainSelector: conceroNetwork.chainSelector,
		nativeUsdRate: 2000e18,
		nativeNativeRate: 1e18,
		lastGasPrice: 1_000_000n,
	});
});
