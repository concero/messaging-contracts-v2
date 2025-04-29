import { type Chain, defineChain } from "viem";
import {
	arbitrumSepolia,
	avalancheFuji,
	base,
	baseSepolia,
	berachainBepolia,
	bitlayerTestnet,
	blastSepolia,
	botanixTestnet,
	bscTestnet,
	celoAlfajores,
	cronosTestnet,
	curtis,
	gnosisChiado,
	hashkeyTestnet,
	hederaTestnet,
	inkSepolia,
	kromaSepolia,
	lineaSepolia,
	mainnet,
	mantleSepoliaTestnet,
	megaethTestnet,
	modeTestnet,
	monadTestnet,
	optimism,
	optimismSepolia,
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
	zksyncSepoliaTestnet,
} from "viem/chains";

import { config } from "./config";
import { ChainSelector } from "./types";

const defaultNativeCurrency = {
	decimals: 18,
	name: "Ether",
	symbol: "ETH",
};

const localhostChain = defineChain({
	id: 1,
	name: "localhost",
	nativeCurrency: defaultNativeCurrency,
	rpcUrls: {
		default: {
			http: config.localhostRpcUrl,
		},
	},
});

const localhostChains: Partial<Record<ChainSelector, Chain>> = {
	"1": localhostChain,
	"10": localhostChain,
};

const liveChains: Partial<Record<string, Chain>> = {
	"1": mainnet,
	"10": optimism,
	"8453": base,

	// @dev testnets
	"421614": arbitrumSepolia,
	"84532": baseSepolia,
	"43113": avalancheFuji,
	"80002": polygonAmoy,
	"11155420": optimismSepolia,
	"81": defineChain({ id: 81, name: "astarShibuya", nativeCurrency: defaultNativeCurrency }),
	"2021": saigon,
	"6342": megaethTestnet,
	"57054": sonicBlazeTestnet,
	"10143": monadTestnet,
	"11155111": sepolia,
	"59141": lineaSepolia,
	"97": bscTestnet,
	"1946": soneiumMinato,
	"200810": bitlayerTestnet,
	"1685877": blastSepolia,
	"3636": botanixTestnet,
	"44787": celoAlfajores,
	"1114": defineChain({ id: 1114, name: "coreTestnet", nativeCurrency: defaultNativeCurrency }),
	"338": cronosTestnet,
	"10200": gnosisChiado,
	"133": hashkeyTestnet,
	"763373": inkSepolia,
	"5003": mantleSepoliaTestnet,
	"534351": scrollSepolia,
	"1328": seiTestnet,
	"157": shibariumTestnet,
	"1301": unichainSepolia,
	"195": xLayerTestnet,
	"48899": zircuitTestnet,
	"919": modeTestnet,
	"33111": curtis,
	"300": zksyncSepoliaTestnet,
	"2358": kromaSepolia,
	"296": hederaTestnet,
	"80069": berachainBepolia,
};

export const viemChains = config.isDevelopment ? localhostChains : liveChains;
