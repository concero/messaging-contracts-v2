import type { Address } from "viem";

import { config } from "../../common/config";

function getConceroVerifier() {
	try {
		if (config.isDevelopment) return secrets.CONCERO_VERIFIER_LOCALHOST;
		return CONCERO_VERIFIER;
	} catch {
		return CONCERO_VERIFIER;
	}
}

export const CONCERO_VERIFIER_CONTRACT_ADDRESS = getConceroVerifier();

export const conceroRouters: Record<number, Address> = {
	// "1": CONCERO_ROUTER_ETHEREUM,
	// "10": CONCERO_ROUTER_OPTIMISM,

	// testnet
	"421614": CONCERO_ROUTER_ARBITRUM_SEPOLIA,
	"84532": CONCERO_ROUTER_BASE_SEPOLIA,
	"43113": CONCERO_ROUTER_AVALANCHE_FUJI,
	"80002": CONCERO_ROUTER_POLYGON_AMOY,
	"11155420": CONCERO_ROUTER_OPTIMISM_SEPOLIA,
	"2021": CONCERO_ROUTER_RONIN_SAIGON,
	"6342": CONCERO_ROUTER_MEGAETH_TESTNET,
	"11155111": CONCERO_ROUTER_SEPOLIA,
	"57054": CONCERO_ROUTER_SONIC_BLAZE,
	"1946": CONCERO_ROUTER_SONEIUM_MINATO,
	"59141": CONCERO_ROUTER_LINEA_SEPOLIA,
	"97": CONCERO_ROUTER_BNB_TESTNET,
	"10143": CONCERO_ROUTER_MONAD_TESTNET,
	"33111": CONCERO_ROUTER_APECHAIN_CURTIS,
	"200810": CONCERO_ROUTER_BITLAYER_TESTNET,
	"1685877": CONCERO_ROUTER_BLAST_SEPOLIA,
	"3636": CONCERO_ROUTER_BOTANIX_TESTNET,
	"44787": CONCERO_ROUTER_CELO_ALFAJORES,
	"10200": CONCERO_ROUTER_GNOSIS_CHIADO,
	"133": CONCERO_ROUTER_HASHKEY_TESTNET,
	"763373": CONCERO_ROUTER_INK_SEPOLIA,
	"5003": CONCERO_ROUTER_MANTLE_SEPOLIA,
	"534351": CONCERO_ROUTER_SCROLL_SEPOLIA,
	"1328": CONCERO_ROUTER_SEI_TESTNET,
	"157": CONCERO_ROUTER_SHIBARIUM_PUPPYNET,
	"1301": CONCERO_ROUTER_UNICHAIN_SEPOLIA,
	"195": CONCERO_ROUTER_XLAYER_SEPOLIA,
	"48899": CONCERO_ROUTER_ZIRCUIT_TESTNET,
	"919": CONCERO_ROUTER_MODE_TESTNET,
};
