import { defineChain } from "viem";

import { urls } from "./rpcUrls";

export const astarShibuya = defineChain({
	id: 81,
	network: "astar-shibuya",
	name: "Astar Shibuya",
	nativeCurrency: { name: "SBY", symbol: "SBY", decimals: 18 },
	testnet: true,
	rpcUrls: {
		default: {
			http: urls.astarShibuya,
		},
	},
});

export const coreTestnet = defineChain({
	id: 1114,
	network: "core-testnet",
	name: "Core testnet",
	nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 },
	testnet: true,
	rpcUrls: {
		default: {
			http: ["https://rpc.test2.btcs.network"],
		},
	},
});

export const apechainCurtis = defineChain({
	id: 33111,
	network: "apechainCurtis",
	name: "apechainCurtis",
	nativeCurrency: { name: "APE", symbol: "APE", decimals: 18 },
	testnet: true,
	rpcUrls: {
		default: {
			http: ["https://rpc.curtis.apechain.com"],
		},
	},
});
