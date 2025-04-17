import { Chain } from "viem";

export type ConceroNetworkType = "mainnet" | "testnet" | "localhost";

export type ConceroNetwork = {
	chainId: number;
	name: string;
	type: ConceroNetworkType;
	chainSelector: bigint;
	accounts: string[];
	viemChain: Chain;
	confirmations: number;
	url: string;
	rpcUrls: string[];
};

export interface ChainDefinition {
	id: number;
	name: string;
	rpcUrls: string[];
	blockExplorer?: {
		name: string;
		url: string;
	};
	isTestnet: boolean;
}

export type ConceroLocalNetwork = ConceroNetwork & {
	saveDeployments?: boolean;
	forking?: {
		url: string;
		enabled: boolean;
		blockNumber?: number;
	};
};
export type ConceroHardhatNetwork = Omit<ConceroLocalNetwork, "accounts"> & {
	accounts: Array<{
		privateKey: string;
		balance: string;
	}>;
};
