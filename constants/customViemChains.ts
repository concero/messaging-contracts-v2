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
