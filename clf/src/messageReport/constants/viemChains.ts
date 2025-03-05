import { type Chain, defineChain } from "viem";
import { arbitrumSepolia, base, baseSepolia, mainnet } from "viem/chains";

import { config } from "../../common/config";

const localhostChain = defineChain({
	id: 1,
	name: "localhost",
	nativeCurrency: {
		decimals: 18,
		name: "Ether",
		symbol: "ETH",
	},
	rpcUrls: {
		default: {
			http: config.localhostRpcUrl,
		},
	},
});

const localhostChains: Record<number, Chain> = {
	1: localhostChain,
	10: localhostChain,
};

const liveChains: Record<number, Chain> = {
	1: mainnet,
	8453: base,

	// @dev testnets
	421614: arbitrumSepolia,
	84532: baseSepolia,
};

export const viemChains = config.isDevelopment ? localhostChains : liveChains;
