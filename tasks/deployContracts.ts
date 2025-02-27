import { task } from "hardhat/config";
import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, type WalletClient, zeroHash } from "viem";

import { conceroNetworks } from "../constants";
import {
	Namespaces as routerNamespaces,
	PriceFeedSlots as routerPriceFeedSlots,
} from "../constants/storage/ConceroRouterStorage";
import {
	Namespaces as verifierNamespaces,
	PriceFeedSlots as verifierPriceFeedSlots,
} from "../constants/storage/ConceroVerifierStorage";
import deployRouter from "../deploy/ConceroRouter";
import deployVerifier from "../deploy/ConceroVerifier";
import { compileContracts, getFallbackClients } from "../utils";

async function deployContracts(
	clfRouterAddress: Address,
): Promise<{ mockCLFRouter: any; conceroVerifier: any; conceroRouter: any }> {
	const hre: HardhatRuntimeEnvironment = require("hardhat");

	const conceroNetwork = conceroNetworks[hre.network.name];
	const { publicClient, walletClient } = getFallbackClients(conceroNetwork);

	const conceroVerifier = await deployVerifier(hre, { clfRouter: clfRouterAddress });
	const conceroRouter = await deployRouter(hre, { conceroVerifier: conceroVerifier.address });

	await setVerifierPriceFeeds(conceroVerifier.address, walletClient);
	await setRouterPriceFeeds(conceroRouter.address, walletClient);

	return { conceroVerifier, conceroRouter };
}

async function setVerifierPriceFeeds(conceroVerifierAddress: string, walletClient: WalletClient) {
	const chainSelector = 1n;
	const nativeUsdRate = 2000e18;
	const nativeNativeRate = 1e18;
	const lastGasPrice = 1_000_000n;

	const { abi: conceroVerifierAbi } = await import(
		"../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const toBytes32 = (value: BigInt) => `0x${value.toString(16).padStart(64, "0")}`;

	await walletClient.writeContract({
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
}

async function setRouterPriceFeeds(conceroRouterAddress: string, walletClient: WalletClient) {
	const chainSelector = 1n;
	const nativeUsdRate = 2000e18;
	const nativeNativeRate = 1e18;
	const lastGasPrice = 1_000_000n;

	const { abi: conceroRouterAbi } = await import(
		"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	const toBytes32 = (value: BigInt) => `0x${value.toString(16).padStart(64, "0")}`;

	await walletClient.writeContract({
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
}

task("operator-setup", "Setup the operator").setAction(async () => {
	await deployContracts();
});

export { deployContracts };
