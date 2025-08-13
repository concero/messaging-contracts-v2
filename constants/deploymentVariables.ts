import { WriteContractParameters } from "viem";
import type { WaitForTransactionReceiptParameters } from "viem/actions/public/waitForTransactionReceipt";

import { ConceroNetwork } from "../types/ConceroNetwork";
import { EnvPrefixes } from "../types/deploymentVariables";

enum ProxyEnum {
	routerProxy = "routerProxy",
	verifierProxy = "verifierProxy",
	priceFeedProxy = "priceFeedProxy",
}

const viemReceiptConfig: WaitForTransactionReceiptParameters = {
	timeout: 0,
	confirmations: 2,
};

const writeContractConfig: WriteContractParameters = {
	gas: 3000000n, // 3M
};

function getViemReceiptConfig(chain: ConceroNetwork): Partial<WaitForTransactionReceiptParameters> {
	return {
		timeout: 0,
		confirmations: chain.confirmations,
	};
}

const envPrefixes: EnvPrefixes = {
	router: "CONCERO_ROUTER",
	routerProxy: "CONCERO_ROUTER_PROXY",
	routerProxyAdmin: "CONCERO_ROUTER_PROXY_ADMIN",
	verifier: "CONCERO_VERIFIER",
	verifierProxy: "CONCERO_VERIFIER_PROXY",
	verifierProxyAdmin: "CONCERO_VERIFIER_PROXY_ADMIN",
	priceFeed: "CONCERO_PRICE_FEED",
	priceFeedProxy: "CONCERO_PRICE_FEED_PROXY",
	priceFeedProxyAdmin: "CONCERO_PRICE_FEED_PROXY_ADMIN",
	lpToken: "LPTOKEN",
	create3Factory: "CREATE3_FACTORY",
	pause: "CONCERO_PAUSE",
};

export { viemReceiptConfig, writeContractConfig, ProxyEnum, envPrefixes, getViemReceiptConfig };
