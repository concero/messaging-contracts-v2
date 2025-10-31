import { config } from "./config";

import { type Chain, defineChain } from "viem";

import { ChainSelector } from "../types";

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

export function getViemChain(chainSelector: string) {
	if (config.isDevelopment) {
		return localhostChains[chainSelector];
	}

	return defineChain({
		id: parseInt(chainSelector),
		nativeCurrency: defaultNativeCurrency,
	});
}
