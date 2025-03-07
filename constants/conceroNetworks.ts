import {
	arbitrum,
	arbitrumSepolia,
	avalanche,
	avalancheFuji,
	base,
	baseSepolia,
	mainnet,
	optimism,
	optimismSepolia,
	polygon,
	polygonAmoy,
	sepolia,
} from "viem/chains";

import {
	ConceroMainnetNetworkNames,
	type ConceroNetwork,
	ConceroNetworkNames,
	ConceroTestNetworkNames,
	ConceroTestnetNetworkNames,
	NetworkType,
} from "../types/ConceroNetwork";
import { getEnvVar, getWallet } from "../utils";
import { hardhatViemChain, localhostViemChain } from "../utils/localhostViemChain";
import { rpcUrl, urls } from "./rpcUrls";

const DEFAULT_BLOCK_CONFIRMATIONS = 2;
const mainnetProxyDeployerPK = getWallet("mainnet", "proxyDeployer", "privateKey");
const testnetProxyDeployerPK = getWallet("testnet", "proxyDeployer", "privateKey");
const localhostProxyDeployerPK = getWallet("localhost", "proxyDeployer", "privateKey");
const mainnetDeployerPK = getWallet("mainnet", "deployer", "privateKey");
const testnetDeployerPK = getWallet("testnet", "deployer", "privateKey");
const localhostDeployerPK = getWallet("localhost", "deployer", "privateKey");

export const networkTypes: Record<NetworkType, NetworkType> = {
	mainnet: "mainnet",
	testnet: "testnet",
	localhost: "localhost",
};

export const networkEnvKeys: Record<ConceroNetworkNames, string> = {
	// mainnets
	ethereum: "ETHEREUM",
	arbitrum: "ARBITRUM",
	optimism: "OPTIMISM",
	polygon: "POLYGON",
	polygonZkEvm: "POLYGON_ZKEVM",
	avalanche: "AVALANCHE",
	base: "BASE",

	// testnets
	sepolia: "SEPOLIA",
	optimismSepolia: "OPTIMISM_SEPOLIA",
	arbitrumSepolia: "ARBITRUM_SEPOLIA",
	avalancheFuji: "FUJI",
	baseSepolia: "BASE_SEPOLIA",
	polygonAmoy: "POLYGON_AMOY",

	//test
	localhost: "LOCALHOST",
	hardhat: "LOCALHOST",
};

export const testingNetworks: Record<ConceroTestNetworkNames, ConceroNetwork> = {
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
		chainSelector: process.env.CL_CCIP_CHAIN_SELECTOR_LOCALHOST as string,
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
		// saveDeployments: false,
		url: rpcUrl.localhost,
		rpcUrls: [rpcUrl.localhost],
		confirmations: 1,
		chainSelector: process.env.CL_CCIP_CHAIN_SELECTOR_LOCALHOST as string,
		accounts: [
			localhostDeployerPK,
			localhostProxyDeployerPK,
			getEnvVar("TESTNET_OPERATOR_PRIVATE_KEY"),
		],
		saveDeployments: true,
	},
};

export const testnetNetworks: Record<ConceroTestnetNetworkNames, ConceroNetwork> = {
	sepolia: {
		name: "sepolia",
		type: networkTypes.testnet,
		chainId: 11155111,
		url: urls.sepolia[0],
		rpcUrls: urls.sepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: "11155111",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: sepolia,
		saveDeployments: false,
	},
	avalancheFuji: {
		name: "avalancheFuji",
		type: networkTypes.testnet,
		chainId: 43113,
		url: urls.avalancheFuji[0],
		rpcUrls: urls.avalancheFuji,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: "43113",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: avalancheFuji,
		saveDeployments: false,
	},
	optimismSepolia: {
		name: "optimismSepolia",
		type: networkTypes.testnet,
		chainId: 11155420,
		url: urls.optimismSepolia[0],
		rpcUrls: urls.optimismSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: "11155420",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: optimismSepolia,
		saveDeployments: false,
	},
	arbitrumSepolia: {
		name: "arbitrumSepolia",
		type: networkTypes.testnet,
		chainId: 421614,
		url: urls.arbitrumSepolia[0],
		rpcUrls: urls.arbitrumSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: "421614",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: arbitrumSepolia,
		saveDeployments: false,
	},
	baseSepolia: {
		name: "baseSepolia",
		type: networkTypes.testnet,
		chainId: 84532,
		url: urls.baseSepolia[0],
		rpcUrls: urls.baseSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: "84532",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: baseSepolia,
		saveDeployments: false,
	},
	polygonAmoy: {
		name: "polygonAmoy",
		type: networkTypes.testnet,
		chainId: 80002,
		url: urls.polygonAmoy[0],
		rpcUrls: urls.polygonAmoy,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: "80002",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: polygonAmoy,
		saveDeployments: false,
	},
};
export const mainnetNetworks: Record<ConceroMainnetNetworkNames, ConceroNetwork> = {
	ethereum: {
		name: "ethereum",
		type: networkTypes.mainnet,
		chainId: 1,
		url: urls.ethereum[0],
		rpcUrls: urls.ethereum,
		accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
		chainSelector: "1",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: mainnet,
		saveDeployments: false,
	},
	base: {
		name: "base",
		type: networkTypes.mainnet,
		chainId: 8453,
		url: urls.base[0],
		rpcUrls: urls.base,
		accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
		chainSelector: "8453",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: base,
		saveDeployments: false,
	},
	arbitrum: {
		name: "arbitrum",
		type: networkTypes.mainnet,
		chainId: 42161,
		url: urls.arbitrum[0],
		rpcUrls: urls.arbitrum,
		accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
		chainSelector: "42161",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: arbitrum,
		saveDeployments: false,
	},
	polygon: {
		name: "polygon",
		type: networkTypes.mainnet,
		chainId: 137,
		url: urls.polygon[0],
		rpcUrls: urls.polygon,
		accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
		chainSelector: "137",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: polygon,
		saveDeployments: false,
	},
	avalanche: {
		name: "avalanche",
		type: networkTypes.mainnet,
		chainId: 43114,
		url: urls.avalanche[0],
		rpcUrls: urls.avalanche,
		accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
		chainSelector: "43114",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: avalanche,
		saveDeployments: false,
	},
	optimism: {
		name: "optimism",
		type: networkTypes.mainnet,
		chainId: 10,
		url: urls.optimism[0],
		rpcUrls: urls.optimism,
		accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
		chainSelector: "10",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: optimism,
		saveDeployments: false,
	},
	polygonZkEvm: {
		chainId: 137,
		name: "polygonZkEvm",
		type: networkTypes.mainnet,
		url: urls.polygonZkEvm[0],
		rpcUrls: urls.polygonZkEvm,
		accounts: [mainnetDeployerPK, mainnetProxyDeployerPK],
		chainSelector: "137",
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: polygon,
		saveDeployments: false,
	},
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

export const conceroNetworks: Record<ConceroNetworkNames, ConceroNetwork> = {
	...testnetNetworks,
	...mainnetNetworks,
	...testingNetworks,
};
