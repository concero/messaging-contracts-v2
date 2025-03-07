import { Chain } from "viem";

export type ConceroMainnetNetworkNames =
	| "ethereum"
	| "arbitrum"
	| "optimism"
	| "polygon"
	| "polygonZkEvm"
	| "avalanche"
	| "base";
export type ConceroTestnetNetworkNames =
	| "localhost"
	| "sepolia"
	| "optimismSepolia"
	| "arbitrumSepolia"
	| "avalancheFuji"
	| "baseSepolia"
	| "polygonAmoy";
export type ConceroTestNetworkNames = "localhost" | "hardhat";

export type ConceroNetworkNames =
	| ConceroMainnetNetworkNames
	| ConceroTestnetNetworkNames
	| ConceroTestNetworkNames;

export type ConceroNetworkType = "mainnet" | "testnet" | "localhost";
export type ConceroNetwork = {
	chainId: number;
	name: ConceroNetworkNames;
	type: ConceroNetworkType;
	chainSelector: bigint;
	accounts: string[];
	viemChain: Chain;
	confirmations: number;
	url: string;
	rpcUrls: string[];
};

export type NetworkType = "mainnet" | "testnet" | "localhost";
