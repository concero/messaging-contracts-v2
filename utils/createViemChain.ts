import { defineChain } from "viem";

import { ChainDefinition } from "../types/ConceroNetwork";

export function createViemChain(chainDefinition: ChainDefinition): ReturnType<typeof defineChain> {
	return defineChain({
		id: chainDefinition.id,
		name: chainDefinition.name,
		nativeCurrency: {
			decimals: 18,
			name: "eth",
			symbol: "eth",
		},
		rpcUrls: {
			default: { http: chainDefinition.rpcUrls },
		},
		blockExplorers: chainDefinition.blockExplorer
			? {
					default: {
						name: chainDefinition.blockExplorer.name,
						url: chainDefinition.blockExplorer.url,
					},
				}
			: undefined,
		testnet: chainDefinition.isTestnet,
	});
}
