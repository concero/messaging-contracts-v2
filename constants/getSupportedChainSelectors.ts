import { ConceroNetworkNames, conceroNetworks } from "./networks";

/**
 * Gets supported chain selectors for the current network type, excluding the current chain
 * @param currentChainName The name of the current chain being deployed to
 * @returns Array of chain selectors for supported chains
 */
function getSupportedChainSelectors(currentChainName: ConceroNetworkNames): string[] {
	const currentChain = conceroNetworks[currentChainName];
	const networkType = currentChain.type;

	return Object.values(conceroNetworks)
		.filter(
			network =>
				network.type === networkType &&
				network.chainSelector &&
				network.name !== currentChainName,
		)
		.map(chain => chain.chainSelector);
}

export { getSupportedChainSelectors };
