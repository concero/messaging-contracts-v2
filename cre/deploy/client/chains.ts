import { type Chain, defineChain } from "viem";

import { config } from "../config";


const defaultNativeCurrency = {
	decimals: 18,
	name: "Ether",
	symbol: "ETH",
};
const defaultLocalChain = defineChain({
	id: 1,
	name: "localhost",
	nativeCurrency: defaultNativeCurrency,
	rpcUrls: {
		default: {
			http: config.localhostRpcUrl,
		},
	},
});

const chainSelectorToChain: Record<string, Chain> = {
	"1": defaultLocalChain,
	"10": defaultLocalChain,
};

export function findChainBySelector(chainSelector: string): Chain {
	if (config.isDevelopment) {
		return chainSelectorToChain[chainSelector];
	}

	return defineChain({
		id: parseInt(chainSelector),
		nativeCurrency: defaultNativeCurrency,
	} as any) as Chain;
}
