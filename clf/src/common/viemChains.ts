import { type Chain, defineChain } from "viem";
import {
	arbitrumSepolia,
	avalancheFuji,
	base,
	baseSepolia,
	mainnet,
	megaethTestnet,
	optimism,
	optimismSepolia,
	polygonAmoy,
	saigon,
} from "viem/chains";

import { config } from "./config";
import { ChainSelector } from "./types";

const defaultNativeCurrency = {
	decimals: 18,
	name: "Ether",
	symbol: "ETH",
};

const localhostChain = defineChain({
	id: 1,
	name: "localhost",
	nativeCurrency: defaultNativeCurrency,
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

const liveChains: Partial<Record<string, Chain>> = {
	"1": mainnet,
	"10": optimism,
	"8453": base,

	// @dev testnets
	"421614": arbitrumSepolia,
	"84532": baseSepolia,
	"43113": avalancheFuji,
	"80002": polygonAmoy,
	"11155420": optimismSepolia,
	"81": defineChain({ id: 81, name: "astarShibuya", nativeCurrency: defaultNativeCurrency }),
	"2021": saigon,
	"6342": megaethTestnet,
};

export const viemChains = config.isDevelopment ? localhostChains : liveChains;
