import {
	ConceroNetwork,
	conceroNetworks as baseNetworks,
	networkTypes,
} from "@concero/contract-utils";
import {
	type ConceroMainnetNetworkNames,
	type ConceroTestnetNetworkNames,
	type NetworkType,
} from "@concero/contract-utils/dist/types";

import { ConceroTestNetworkNames } from "../types/ConceroNetwork";
import { getEnvVar, getWallet } from "../utils";
import { hardhatViemChain, localhostViemChain } from "../utils/localhostViemChain";
import { rpcUrl, urls } from "./rpcUrls";

const mainnetProxyDeployerPK = getWallet("mainnet", "proxyDeployer", "privateKey");
const testnetProxyDeployerPK = getWallet("testnet", "proxyDeployer", "privateKey");
const localhostProxyDeployerPK = getWallet("localhost", "proxyDeployer", "privateKey");
const mainnetDeployerPK = getWallet("mainnet", "deployer", "privateKey");
const testnetDeployerPK = getWallet("testnet", "deployer", "privateKey");
const localhostDeployerPK = getWallet("localhost", "deployer", "privateKey");

const testnetAccounts = [testnetDeployerPK, testnetProxyDeployerPK];

export interface ExtendedConceroNetwork extends ConceroNetwork {
	url?: string;
	rpcUrls?: string[];
	accounts?: any[];
	saveDeployments?: boolean;
	forking?: {
		url: string;
		enabled: boolean;
		blockNumber: number;
	};
}

const testingNetworks: Record<"localhost" | "hardhat", ExtendedConceroNetwork> = {
	hardhat: {
		name: "hardhat",
		chainId: Number(process.env.LOCALHOST_FORK_CHAIN_ID),
		type: networkTypes.localhost,
		saveDeployments: false,
		accounts: [
			{
				privateKey: localhostProxyDeployerPK,
				balance: "10000000000000000000000",
			},
			{
				privateKey: localhostDeployerPK,
				balance: "10000000000000000000000",
			},
			{
				privateKey: getEnvVar("TESTNET_OPERATOR_PRIVATE_KEY"),
				balance: "10000000000000000000000",
			},
			{
				privateKey: getEnvVar("TESTNET_USER_PRIVATE_KEY"),
				balance: "10000000000000000000000",
			},
		],
		chainSelector: Number(process.env.CL_CCIP_CHAIN_SELECTOR_LOCALHOST || "0"),
		confirmations: 1,
		viemChain: hardhatViemChain,
		forking: {
			url: `https://base-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
			enabled: false,
			blockNumber: Number(process.env.LOCALHOST_FORK_LATEST_BLOCK_NUMBER),
		},
	},
	localhost: {
		name: "localhost",
		type: networkTypes.localhost,
		chainId: 1,
		viemChain: localhostViemChain,
		url: rpcUrl.localhost,
		rpcUrls: [rpcUrl.localhost],
		confirmations: 1,
		chainSelector: Number(process.env.CL_CCIP_CHAIN_SELECTOR_LOCALHOST || "0"),
		accounts: [
			localhostDeployerPK,
			localhostProxyDeployerPK,
			getEnvVar("TESTNET_OPERATOR_PRIVATE_KEY"),
		],
		saveDeployments: true, // Keep this as true for localhost as in the original
	},
};

// Extend the testnet networks with additional fields
const extendedTestnetNetworks: Record<ConceroTestnetNetworkNames, ExtendedConceroNetwork> =
	Object.fromEntries(
		Object.entries(baseNetworks)
			.filter(
				([key]) =>
					Object.keys(baseNetworks).includes(key) &&
					!Object.keys(testingNetworks).includes(key),
			)
			.map(([key, network]) => {
				const networkKey = key as ConceroTestnetNetworkNames;
				return [
					networkKey,
					{
						...network,
						url: urls[networkKey]?.[0],
						rpcUrls: urls[networkKey],
						accounts: testnetAccounts,
						saveDeployments: false,
					},
				];
			}),
	) as Record<ConceroTestnetNetworkNames, ExtendedConceroNetwork>;

// Extend the mainnet networks with additional fields
const extendedMainnetNetworks: Record<ConceroMainnetNetworkNames, ExtendedConceroNetwork> =
	Object.fromEntries(
		Object.entries(baseNetworks)
			.filter(
				([key]) =>
					Object.keys(baseNetworks).includes(key) &&
					Object.keys(baseNetworks).includes(key),
			)
			.map(([key, network]) => {
				const networkKey = key as ConceroMainnetNetworkNames;
				return [
					networkKey,
					{
						...network,
						url: urls[networkKey]?.[0],
						rpcUrls: urls[networkKey],
						accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
						saveDeployments: false,
					},
				];
			}),
	) as Record<ConceroMainnetNetworkNames, ExtendedConceroNetwork>;

// Combined networks
export type ConceroNetworkNames =
	| ConceroMainnetNetworkNames
	| ConceroTestnetNetworkNames
	| ConceroTestNetworkNames;

export const mainnetNetworks = extendedMainnetNetworks;
export const testnetNetworks = extendedTestnetNetworks;

export const conceroNetworks: Record<ConceroNetworkNames, ExtendedConceroNetwork> = {
	...extendedTestnetNetworks,
	...extendedMainnetNetworks,
	...testingNetworks,
};

export function getConceroVerifierNetwork(type: NetworkType): ExtendedConceroNetwork {
	switch (type) {
		case networkTypes.mainnet:
			return mainnetNetworks.arbitrum;
		case networkTypes.testnet:
			return testnetNetworks.arbitrumSepolia;
		case networkTypes.localhost:
			return testingNetworks.localhost;
		default:
			throw new Error(`Invalid network type: ${type}`);
	}
}
