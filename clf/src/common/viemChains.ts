import { type Chain, defineChain } from "viem";
import { arbitrumSepolia, base, baseSepolia, mainnet, optimism } from "viem/chains";

import { config } from "./config";
import { ChainSelector } from "./types";

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

const localhostChains: Partial<Record<ChainSelector, Chain>> = {
	"1": localhostChain,
	"10": localhostChain,
};

const liveChains: Partial<Record<ChainSelector, Chain>> = {
	"1": mainnet,
	"10": optimism,
	"8453": base,

	// @dev testnets
	"421614": arbitrumSepolia,
	"84532": baseSepolia,
};

export const viemChains = config.isDevelopment ? localhostChains : liveChains;
