import { type NetworkType } from "@concero/contract-utils/dist/types";
import {
	mainnetNetworks as v2MainnetNetworks,
	testnetNetworks as v2TestnetNetworks,
} from "@concero/v2-networks";

import {
	ChainDefinition,
	ConceroHardhatNetwork,
	ConceroLocalNetwork,
	ConceroNetwork,
} from "../types/ConceroNetwork";
import { getEnvVar, getWallet } from "../utils";
import { createViemChain } from "../utils/createViemChain";
import { urls } from "./rpcUrls";

const mainnetProxyDeployerPK = getWallet("mainnet", "proxyDeployer", "privateKey");
const testnetProxyDeployerPK = getWallet("testnet", "proxyDeployer", "privateKey");
const localhostProxyDeployerPK = getWallet("localhost", "proxyDeployer", "privateKey");
const mainnetDeployerPK = getWallet("mainnet", "deployer", "privateKey");
const testnetDeployerPK = getWallet("testnet", "deployer", "privateKey");
const localhostDeployerPK = getWallet("localhost", "deployer", "privateKey");

const testnetAccounts = [testnetDeployerPK, testnetProxyDeployerPK];

const networkTypes: Record<NetworkType, NetworkType> = {
	mainnet: "mainnet",
	testnet: "testnet",
	localhost: "localhost",
};

const hardhatViemChain = createViemChain({
	id: Number(process.env.LOCALHOST_FORK_CHAIN_ID),
	name: "hardhat",
	rpcUrls: ["http://127.0.0.1:8545"],
	isTestnet: true,
});

const localhostViemChain = createViemChain({
	id: Number(process.env.LOCALHOST_FORK_CHAIN_ID || "1"),
	name: "localhost",
	rpcUrls: [process.env.LOCALHOST_RPC_URL || "http://localhost:8545"],
	isTestnet: true,
});

const testingNetworks: Record<"localhost", ConceroLocalNetwork> &
	Record<"hardhat", ConceroHardhatNetwork> = {
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
		chainSelector: BigInt(process.env.CL_CCIP_CHAIN_SELECTOR_LOCALHOST || "0"),
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
		confirmations: 1,
		chainSelector: BigInt(process.env.CL_CCIP_CHAIN_SELECTOR_LOCALHOST || "0"),
		accounts: [
			localhostDeployerPK,
			localhostProxyDeployerPK,
			getEnvVar("TESTNET_OPERATOR_PRIVATE_KEY"),
		],
		saveDeployments: true,
		url: process.env.LOCALHOST_RPC_URL || "http://localhost:8545",
	},
};

export type ConceroMainnetNetworkNames = keyof typeof v2MainnetNetworks;
export type ConceroTestnetNetworkNames = keyof typeof v2TestnetNetworks;

function createExtendedNetworks<T extends string>(
	networks: Record<string, any>,
	networkType: NetworkType,
	accounts: string[],
	isTestnet: boolean,
): Record<T, ConceroNetwork> {
	return Object.fromEntries(
		Object.entries(networks).map(([key, network]) => {
			const networkKey = key as T;

			const chainDefinition: ChainDefinition = {
				id: network.chainId,
				name: network.name,
				rpcUrls: network.rpcs || [],
				isTestnet,
				...(network.blockExplorers && network.blockExplorers.length > 0
					? {
							blockExplorer: {
								name: network.blockExplorers[0].name,
								url: network.blockExplorers[0].url,
							},
						}
					: {}),
			};

			const viemChain = createViemChain(chainDefinition);

			return [
				networkKey,
				{
					name: network.name,
					chainId: network.chainId,
					type: networkType,
					url: network.rpcs?.[0] || urls[networkKey]?.[0] || "",
					saveDeployments: true,
					accounts,
					chainSelector: BigInt(network.chainSelector),
					confirmations: 1,
					viemChain,
				},
			];
		}),
	) as Record<T, ConceroNetwork>;
}

export const testnetNetworks = createExtendedNetworks<ConceroTestnetNetworkNames>(
	v2TestnetNetworks,
	networkTypes.testnet,
	testnetAccounts,
	true,
);

export const mainnetNetworks = createExtendedNetworks<ConceroMainnetNetworkNames>(
	v2MainnetNetworks,
	networkTypes.mainnet,
	[mainnetDeployerPK, mainnetProxyDeployerPK],
	false,
);

export const conceroNetworks: Record<
	ConceroMainnetNetworkNames | ConceroTestnetNetworkNames | "localhost" | "hardhat",
	ConceroNetwork | ConceroLocalNetwork | ConceroHardhatNetwork
> = {
	...testnetNetworks,
	...mainnetNetworks,
	...testingNetworks,
};

export function getConceroVerifierNetwork(type: NetworkType): ConceroNetwork {
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
