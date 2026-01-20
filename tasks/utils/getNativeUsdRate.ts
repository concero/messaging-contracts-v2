import { ConceroNetwork } from "@concero/contract-utils";
import { formatEther } from "viem";

import { ProxyEnum, conceroNetworks } from "../../constants";
import { err, getEnvAddress, getFallbackClients, log } from "../../utils";

interface ConceroPriceFeedInfo {
	chainName: string;
	contractAlias: string;
	contractAddress: string;
	nativeUsdRate: string;
}

async function getAvailableNativeUsdRates(
	isTestnet: boolean,
	chainNames?: string[],
	needShowErrors?: boolean,
): Promise<ConceroPriceFeedInfo[]> {
	const { abi } = await import(
		"../../artifacts/contracts/ConceroPriceFeed/ConceroPriceFeed.sol/ConceroPriceFeed.json"
	);
	const results: ConceroPriceFeedInfo[] = [];

	// Process networks based on testnet flag and optional chain filter
	const networksToCheck = Object.entries(conceroNetworks)
		.filter(([_, network]) =>
			isTestnet ? network.type === "testnet" : network.type === "mainnet",
		)
		.filter(([name, _]) => !chainNames || chainNames.includes(name))
		.map(([name, network]) => ({ name, network: network as ConceroNetwork }));

	for (const { name, network } of networksToCheck) {
		try {
			const [contractAddress, contractAlias] = getEnvAddress(ProxyEnum.priceFeedProxy, name);
			const { publicClient } = getFallbackClients(network);

			const nativeUsdRate = (await publicClient.readContract({
				address: contractAddress,
				abi,
				functionName: "getNativeUsdRate",
			})) as bigint;

			if (nativeUsdRate > BigInt(0)) {
				results.push({
					chainName: name,
					contractAlias,
					contractAddress,
					nativeUsdRate: formatEther(nativeUsdRate),
				});
			}
		} catch (error) {
			const errorMessage = error instanceof Error ? error.message : String(error);
			if (needShowErrors) {
				err(
					`Error checking native usd rate on ${name}: ${errorMessage}`,
					"getNativeUsdRate",
				);
			} else {
				err(`Error checking price feed info on ${name}`, "getNativeUsdRate");
			}
		}
	}

	return results;
}

export async function getNativeUsdRate(
	chains: string,
	isTestnet?: boolean,
	needShowErrors?: boolean,
): Promise<void> {
	let chainNames: string[] | undefined;

	// Parse chains parameter if provided
	if (chains && chains.trim() !== "") {
		chainNames = chains
			.split(",")
			.map(chain => chain.trim())
			.filter(Boolean);
		log(
			`Checking native usd rate for specific chains: ${chainNames.join(", ")}`,
			"getNativeUsdRate",
		);
	} else {
		log(
			`Checking price feed info for all ${isTestnet ? "testnet" : "mainnet"} chains`,
			"getNativeUsdRate",
		);
	}

	const availableNativeUsdRates = await getAvailableNativeUsdRates(
		isTestnet ?? false,
		chainNames,
		needShowErrors,
	);

	if (availableNativeUsdRates.length === 0) {
		log("No native usd rate found on any chains", "getNativeUsdRate");
		return;
	}

	// Display available price feeds
	log("Available native usd rates found:", "getNativeUsdRate");
	const displayNativeUsdRates = availableNativeUsdRates.map(priceFeed => ({
		Chain: priceFeed.chainName,
		Contract: priceFeed.contractAlias,
		"Native USD Rate (ETH)": priceFeed.nativeUsdRate,
	}));
	console.table(displayNativeUsdRates);
}
