import { formatUnits } from "viem";

import { ProxyEnum, conceroNetworks } from "../../constants";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { err, getEnvAddress, getFallbackClients, log } from "../../utils";

interface ConceroPriceFeedInfo {
	srcChainName: string;
	contractAlias: string;
	contractAddress: string;
	lastGasPrice: string;
}

async function getAvailableLastGasPrices(
	isTestnet: boolean,
	srcChainName: string,
	chainNames?: string[],
): Promise<ConceroPriceFeedInfo[]> {
	const { abi } = await import(
		"../../artifacts/contracts/ConceroPriceFeed/ConceroPriceFeed.sol/ConceroPriceFeed.json"
	);
	const results: ConceroPriceFeedInfo[] = [];

	const sourceNetwork = conceroNetworks[srcChainName];
	if (!sourceNetwork) {
		err(`Source chain ${srcChainName} not found`, "getLastGasPrice");
		return results;
	}

	if (
		(isTestnet && sourceNetwork.type !== "testnet") ||
		(!isTestnet && sourceNetwork.type !== "mainnet")
	) {
		err(`Source chain ${srcChainName} type doesn't match testnet flag`, "getLastGasPrice");
		return results;
	}

	let sourceContract;
	try {
		const [contractAddress, contractAlias] = getEnvAddress(
			ProxyEnum.priceFeedProxy,
			srcChainName,
		);
		const { publicClient } = getFallbackClients(sourceNetwork);
		sourceContract = { contractAddress, contractAlias, publicClient };
	} catch (error) {
		err(`Failed to get source contract for ${srcChainName}`, "getLastGasPrice");
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
			const gasPrice = (await sourceContract.publicClient.readContract({
				address: sourceContract.contractAddress,
				abi,
				functionName: "getLastGasPrice",
				args: [network.chainSelector],
			})) as bigint;

			if (gasPrice > BigInt(0)) {
				results.push({
					srcChainName: name,
					contractAlias: sourceContract.contractAlias,
					contractAddress: sourceContract.contractAddress,
					lastGasPrice: formatUnits(gasPrice, 9),
				});
			}
		} catch (error) {
			const errorMessage = error instanceof Error ? error.message : String(error);
			err(`Error checking gas price for ${name}: ${errorMessage}`, "getLastGasPrice");
		}
	}

	return results;
}

export async function getLastGasPrice(
	chains: string,
	srcChainName?: string,
	isTestnet?: boolean,
): Promise<void> {
	let chainNames: string[] | undefined;

	const sourceChainName = srcChainName || (isTestnet ? "arbitrumSepolia" : "arbitrum");

	// Parse chains parameter if provided
	if (chains && chains.trim() !== "") {
		chainNames = chains
			.split(",")
			.map(chain => chain.trim())
			.filter(Boolean);
		log(
			`Checking last gas price for specific chains: ${chainNames.join(", ")} from source: ${sourceChainName}`,
			"getLastGasPrice",
		);
	} else {
		log(
			`Checking last gas price for all ${isTestnet ? "testnet" : "mainnet"} chains from source: ${sourceChainName}`,
			"getLastGasPrice",
		);
	}

	const availableLastGasPrices = await getAvailableLastGasPrices(
		isTestnet ?? false,
		sourceChainName,
		chainNames,
	);

	if (availableLastGasPrices.length === 0) {
		log("No last gas price found on any chains", "getLastGasPrice");
		return;
	}

	log(`Available last gas prices from ${sourceChainName}:`, "getLastGasPrice");
	const displayLastGasPrices = availableLastGasPrices.map(priceFeed => ({
		Chain: priceFeed.srcChainName,
		Contract: priceFeed.contractAlias,
		"Gas Price (gwei)": priceFeed.lastGasPrice,
	}));
	console.table(displayLastGasPrices);
}
