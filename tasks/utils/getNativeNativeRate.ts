import { formatEther } from "viem";

import { ProxyEnum, conceroNetworks } from "../../constants";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { err, getEnvAddress, getFallbackClients, log } from "../../utils";

interface ConceroPriceFeedInfo {
	chainName: string;
	contractAlias: string;
	contractAddress: string;
	nativeNativeRate: string;
}

async function getAvailableNativeNativeRates(
	sourceChain: string,
	isTestnet: boolean,
	chainNames?: string[],
): Promise<ConceroPriceFeedInfo[]> {
	const { abi } = await import(
		"../../artifacts/contracts/ConceroPriceFeed/ConceroPriceFeed.sol/ConceroPriceFeed.json"
	);
	const results: ConceroPriceFeedInfo[] = [];

	const sourceNetwork = conceroNetworks[sourceChain as keyof typeof conceroNetworks];
	if (!sourceNetwork) {
		err(`Source chain ${sourceChain} not found`, "getNativeNativeRate");
		return results;
	}

	if (
		(isTestnet && sourceNetwork.type !== "testnet") ||
		(!isTestnet && sourceNetwork.type !== "mainnet")
	) {
		err(`Source chain ${sourceChain} type doesn't match testnet flag`, "getNativeNativeRate");
		return results;
	}

	let sourceContract;
	try {
		const [contractAddress, contractAlias] = getEnvAddress(
			ProxyEnum.priceFeedProxy,
			sourceChain,
		);
		const { publicClient } = getFallbackClients(sourceNetwork);
		sourceContract = { contractAddress, contractAlias, publicClient };
	} catch (error) {
		err(`Failed to get source contract for ${sourceChain}`, "getNativeNativeRate");
		return results;
	}

	const networksToCheck = Object.entries(conceroNetworks)
		.filter(([_, network]) =>
			isTestnet ? network.type === "testnet" : network.type === "mainnet",
		)
		.filter(([name, _]) => !chainNames || chainNames.includes(name))
		.map(([name, network]) => ({ name, network: network as ConceroNetwork }));

	for (const { name, network } of networksToCheck) {
		try {
			const nativeNativeRate = (await sourceContract.publicClient.readContract({
				address: sourceContract.contractAddress,
				abi,
				functionName: "getNativeNativeRate",
				args: [network.chainSelector],
			})) as bigint;

			if (nativeNativeRate > BigInt(0)) {
				results.push({
					chainName: name,
					contractAlias: sourceContract.contractAlias,
					contractAddress: sourceContract.contractAddress,
					nativeNativeRate: formatEther(nativeNativeRate),
				});
			}
		} catch (error) {
			const errorMessage = error instanceof Error ? error.message : String(error);
			err(
				`Error checking native-native rate for ${name}: ${errorMessage}`,
				"getNativeNativeRate",
			);
		}
	}

	return results;
}

export async function getNativeNativeRate(
	sourceChain: string,
	chains: string,
	isTestnet?: boolean,
): Promise<void> {
	let chainNames: string[] | undefined;

	// Parse chains parameter if provided
	if (chains && chains.trim() !== "") {
		chainNames = chains
			.split(",")
			.map(chain => chain.trim())
			.filter(Boolean);
		log(
			`Checking native-native rate for specific chains from source: ${sourceChain}`,
			"getNativeNativeRate",
		);
	} else {
		log(
			`Checking native-native rate for all ${isTestnet ? "testnet" : "mainnet"} chains from source: ${sourceChain}`,
			"getNativeNativeRate",
		);
	}

	const availableNativeNativeRates = await getAvailableNativeNativeRates(
		sourceChain,
		isTestnet ?? false,
		chainNames,
	);

	if (availableNativeNativeRates.length === 0) {
		log("No native-native rate found on any chains", "getNativeNativeRate");
		return;
	}

	// Display available price feeds
	log(`Available native-native rates from ${sourceChain}:`, "getNativeNativeRate");
	const displayNativeNativeRates = availableNativeNativeRates.map(priceFeed => ({
		Chain: priceFeed.chainName,
		Contract: priceFeed.contractAlias,
		"Native-Native Rate": priceFeed.nativeNativeRate,
	}));
	console.table(displayNativeNativeRates);
}
