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
	"1": CONCERO_ROUTER_ETHEREUM,
	"10": CONCERO_ROUTER_OPTIMISM,

	// testnet
	"421614": CONCERO_ROUTER_ARBITRUM_SEPOLIA,
	"84532": CONCERO_ROUTER_BASE_SEPOLIA,
};
