import { Chain } from "viem";

export type ConceroMainnetNetworkNames =
    | "mainnet"
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

export type ConceroNetworkNames = ConceroMainnetNetworkNames | ConceroTestnetNetworkNames | ConceroTestNetworkNames;

export type ConceroNetwork = {
    id: number;
    name: ConceroNetworkNames;
    type: "mainnet" | "testnet";
    chainSelector: string;
    accounts: string[];
    viemChain: Chain;
    confirmations: number;
    url: string;
    rpcUrls: string[];
};

export type NetworkType = "mainnet" | "testnet" | "test";
