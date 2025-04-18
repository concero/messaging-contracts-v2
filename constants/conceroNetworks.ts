import {
	arbitrum,
	arbitrumSepolia,
	avalanche,
	avalancheFuji,
	base,
	baseSepolia,
	bitlayerTestnet,
	blastSepolia,
	botanixTestnet,
	bscTestnet,
	celoAlfajores,
	cronosTestnet,
	gnosisChiado,
	hashkeyTestnet,
	inkSepolia,
	lineaSepolia,
	mainnet,
	mantleSepoliaTestnet,
	megaethTestnet,
	modeTestnet,
	monadTestnet,
	optimism,
	optimismSepolia,
	polygon,
	polygonAmoy,
	saigon,
	scrollSepolia,
	seiTestnet,
	sepolia,
	shibariumTestnet,
	soneiumMinato,
	sonicBlazeTestnet,
	unichainSepolia,
	xLayerTestnet,
	zircuitTestnet,
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
import { apechainCurtis, astarShibuya, coreTestnet } from "./customViemChains";
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

const testnetAccounts = [testnetDeployerPK, testnetProxyDeployerPK];
const saveDeployments = false;

export const networkEnvKeys: Record<ConceroNetworkNames, string> = {
	//test
	localhost: "LOCALHOST",
	hardhat: "LOCALHOST",
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
	avalancheFuji: "AVALANCHE_FUJI",
	baseSepolia: "BASE_SEPOLIA",
	polygonAmoy: "POLYGON_AMOY",
	lineaSepolia: "LINEA_SEPOLIA",
	bnbTestnet: "BNB_TESTNET",
	soneiumMinato: "SONEIUM_MINATO",
	sonicBlaze: "SONIC_BLAZE",
	astarShibuya: "ASTAR_SHIBUYA",
	roninSaigon: "RONIN_SAIGON",
	megaethTestnet: "MEGAETH_TESTNET",
	berachainBepolia: "BERACHAIN_BEPOLIA",
	sonicBlaze: "SONIC_BLAZE",
	apechainCurtis: "APECHAIN_CURTIS",
	bitlayerTestnet: "BITLAYER_TESTNET",
	blastSepolia: "BLAST_SEPOLIA",
	botanixTestnet: "BOTANIX_TESTNET",
	celoAlfajores: "CELO_ALFAJORES",
	coreTestnet: "CORE_TESTNET",
	cronosTestnet: "CRONOS_TESTNET",
	gnosisChiado: "GNOSIS_CHIADO",
	hashkeyTestnet: "HASHKEY_TESTNET",
	inkSepolia: "INK_SEPOLIA",
	mantleSepolia: "MANTLE_SEPOLIA",
	scrollSepolia: "SCROLL_SEPOLIA",
	seiTestnet: "SEI_TESTNET",
	shibariumPuppynet: "SHIBARIUM_PUPPYNET",
	unichainSepolia: "UNICHAIN_SEPOLIA",
	monadTestnet: "MONAD_TESTNET",
	xlayerSepolia: "XLAYER_SEPOLIA",
	zircuitTestnet: "ZIRCUIT_TESTNET",
	modeTestnet: "MODE_TESTNET",
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
	arbitrumSepolia: {
		name: "arbitrumSepolia",
		type: networkTypes.testnet,
		chainId: 421614,
		url: urls.arbitrumSepolia[0],
		rpcUrls: urls.arbitrumSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 421614n,
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
		chainSelector: 84532n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: baseSepolia,
		saveDeployments: false,
	},
	astarShibuya: {
		name: "astarShibuya",
		type: networkTypes.testnet,
		chainId: 81,
		url: urls.astarShibuya[0],
		rpcUrls: urls.astarShibuya,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 81n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: astarShibuya,
		saveDeployments: false,
	},
	roninSaigon: {
		name: "roninSaigon",
		type: networkTypes.testnet,
		chainId: 2021,
		url: urls.roninSaigon[0],
		rpcUrls: urls.roninSaigon,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 2021n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: saigon,
		saveDeployments: false,
	},
	megaethTestnet: {
		name: "megaethTestnet",
		type: networkTypes.testnet,
		chainId: 6342,
		url: urls.megaethTestnet[0],
		rpcUrls: urls.megaethTestnet,
		accounts: testnetAccounts,
		chainSelector: 6342n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: megaethTestnet,
		saveDeployments: false,
	},
	sonicBlaze: {
		name: "sonicBlaze",
		type: networkTypes.testnet,
		chainId: 57054,
		url: urls.sonicBlaze[0],
		rpcUrls: urls.sonicBlaze,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 57054,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: sonicBlazeTestnet,
		saveDeployments: false,
	},
	monadTestnet: {
		name: "monadTestnet",
		type: networkTypes.testnet,
		chainId: 10_143,
		url: urls.monadTestnet[0],
		rpcUrls: urls.monadTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 10_143n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: monadTestnet,
		saveDeployments: false,
	},

	sepolia: {
		name: "sepolia",
		type: networkTypes.testnet,
		chainId: 11155111,
		url: urls.sepolia[0],
		rpcUrls: urls.sepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 11155111,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: sepolia,
		saveDeployments: false,
	},
	lineaSepolia: {
		name: "lineaSepolia",
		type: networkTypes.testnet,
		chainId: 59141,
		url: urls.lineaSepolia[0],
		rpcUrls: urls.lineaSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 59141,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: lineaSepolia,
		saveDeployments: false,
	},
	bnbTestnet: {
		name: "bnbTestnet",
		type: networkTypes.testnet,
		chainId: 97,
		url: urls.bnbTestnet[0],
		rpcUrls: urls.bnbTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 97,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: bscTestnet,
		saveDeployments: false,
	},
	soneiumMinato: {
		name: "soneiumMinato",
		type: networkTypes.testnet,
		chainId: 1946,
		url: urls.soneiumMinato[0],
		rpcUrls: urls.soneiumMinato,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 1946,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: soneiumMinato,
		saveDeployments: false,
	},
	apechainCurtis: {
		name: "apechainCurtis",
		type: networkTypes.testnet,
		chainId: 33111,
		url: urls.apechainCurtis[0],
		rpcUrls: urls.apechainCurtis,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 33111,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: apechainCurtis,
		saveDeployments,
	},
	avalancheFuji: {
		name: "avalancheFuji",
		type: networkTypes.testnet,
		chainId: 43113,
		url: urls.avalancheFuji[0],
		rpcUrls: urls.avalancheFuji,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 43113,
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
		chainSelector: 11155420n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: optimismSepolia,
		saveDeployments: false,
	},
	polygonAmoy: {
		name: "polygonAmoy",
		type: networkTypes.testnet,
		chainId: 80002,
		url: urls.polygonAmoy[0],
		rpcUrls: urls.polygonAmoy,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 80002n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: polygonAmoy,
		saveDeployments,
	},
	bitlayerTestnet: {
		name: "bitlayerTestnet",
		type: networkTypes.testnet,
		chainId: 200810,
		url: urls.bitlayerTestnet[0],
		rpcUrls: urls.bitlayerTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 200810n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: bitlayerTestnet,
		saveDeployments,
	},
	blastSepolia: {
		name: "blastSepolia",
		type: networkTypes.testnet,
		chainId: 168587773,
		url: urls.blastSepolia[0],
		rpcUrls: urls.blastSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 1685877n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: blastSepolia,
		saveDeployments,
	},
	botanixTestnet: {
		name: "botanixTestnet",
		type: networkTypes.testnet,
		chainId: 3636,
		url: urls.botanixTestnet[0],
		rpcUrls: urls.botanixTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 3636n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: botanixTestnet,
		saveDeployments,
	},
	celoAlfajores: {
		name: "celoAlfajores",
		type: networkTypes.testnet,
		chainId: 44_787,
		url: urls.celoAlfajores[0],
		rpcUrls: urls.celoAlfajores,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 44_787n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: celoAlfajores,
		saveDeployments,
	},
	coreTestnet: {
		name: "coreTestnet",
		type: networkTypes.testnet,
		chainId: 1114,
		url: urls.coreTestnet[0],
		rpcUrls: urls.coreTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 1114n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: coreTestnet,
		saveDeployments,
	},
	cronosTestnet: {
		name: "cronosTestnet",
		type: networkTypes.testnet,
		chainId: 338,
		url: urls.cronosTestnet[0],
		rpcUrls: urls.cronosTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 338n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: cronosTestnet,
		saveDeployments,
	},
	gnosisChiado: {
		name: "gnosisChiado",
		type: networkTypes.testnet,
		chainId: 10_200,
		url: urls.gnosisChiado[0],
		rpcUrls: urls.gnosisChiado,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 10_200n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: gnosisChiado,
		saveDeployments,
	},
	hashkeyTestnet: {
		name: "hashkeyTestnet",
		type: networkTypes.testnet,
		chainId: 133,
		url: urls.hashkeyTestnet[0],
		rpcUrls: urls.hashkeyTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 133n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: hashkeyTestnet,
		saveDeployments,
	},
	inkSepolia: {
		name: "inkSepolia",
		type: networkTypes.testnet,
		chainId: 763373,
		url: urls.inkSepolia[0],
		rpcUrls: urls.inkSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 763373n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: inkSepolia,
		saveDeployments,
	},
	mantleSepolia: {
		name: "mantleSepolia",
		type: networkTypes.testnet,
		chainId: 5003,
		url: urls.mantleSepolia[0],
		rpcUrls: urls.mantleSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 5003n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: mantleSepoliaTestnet,
		saveDeployments,
	},
	scrollSepolia: {
		name: "scrollSepolia",
		type: networkTypes.testnet,
		chainId: 534351,
		url: urls.scrollSepolia[0],
		rpcUrls: urls.scrollSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 534351n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: scrollSepolia,
		saveDeployments,
	},
	seiTestnet: {
		name: "seiTestnet",
		type: networkTypes.testnet,
		chainId: 1328,
		url: urls.seiTestnet[0],
		rpcUrls: urls.seiTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 1328n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: seiTestnet,
		saveDeployments,
	},
	shibariumPuppynet: {
		name: "shibariumPuppynet",
		type: networkTypes.testnet,
		chainId: 157,
		url: urls.shibariumPuppynet[0],
		rpcUrls: urls.shibariumPuppynet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 157n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: shibariumTestnet,
		saveDeployments,
	},
	unichainSepolia: {
		name: "unichainSepolia",
		type: networkTypes.testnet,
		chainId: 1301,
		url: urls.unichainSepolia[0],
		rpcUrls: urls.unichainSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 1301n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: unichainSepolia,
		saveDeployments,
	},
	xlayerSepolia: {
		name: "xlayerSepolia",
		type: networkTypes.testnet,
		chainId: 195,
		url: urls.xlayerSepolia[0],
		rpcUrls: urls.xlayerSepolia,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 195n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: xLayerTestnet,
		saveDeployments,
	},
	zircuitTestnet: {
		name: "zircuitTestnet",
		type: networkTypes.testnet,
		chainId: 48899,
		url: urls.zircuitTestnet[0],
		rpcUrls: urls.zircuitTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 48899n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: zircuitTestnet,
		saveDeployments,
	},
	modeTestnet: {
		name: "modeTestnet",
		type: networkTypes.testnet,
		chainId: 919,
		url: urls.modeTestnet[0],
		rpcUrls: urls.modeTestnet,
		accounts: [testnetDeployerPK, testnetProxyDeployerPK],
		chainSelector: 919n,
		confirmations: DEFAULT_BLOCK_CONFIRMATIONS,
		viemChain: modeTestnet,
		saveDeployments,
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
		chainSelector: 1n,
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
		chainSelector: 8453n,
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
		chainSelector: 42161n,
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
		chainSelector: 137n,
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
		chainSelector: 43114n,
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
		chainSelector: 10n,
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
		chainSelector: 137n,
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
