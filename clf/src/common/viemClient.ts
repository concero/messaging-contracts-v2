import { Transport, createPublicClient, fallback, http } from "viem";

import { config } from "./config";
import { handleError } from "./errorHandler";
import { ErrorType } from "./errorType";
import { rpcConfigs } from "./rpcLoader";
import { ChainSelector } from "./types";
import { getViemChain } from "./viemChains";

function getRpcConfigForChain(chainSelector: ChainSelector) {
	if (config.isDevelopment) {
		return {
			id: chainSelector,
			urls: [config.localhostRpcUrl],
		};
	}

	return rpcConfigs[chainSelector];
}

export function createFallbackTransport(chainSelector: ChainSelector): Transport {
	const rpcConfig = getRpcConfigForChain(chainSelector);

	if (!rpcConfig || !rpcConfig.rpcUrls || rpcConfig.rpcUrls.length === 0) {
		handleError(ErrorType.NO_RPC_PROVIDERS);
	}

	const transportFactories = rpcConfig.rpcUrls.map(url =>
		http(url.startsWith("http") ? url : `https://${url}`, { batch: true }),
	);
	return fallback(transportFactories);
}

export function getPublicClient(chainSelector: ChainSelector) {
	return createPublicClient({
		transport: createFallbackTransport(chainSelector),
		chain: getViemChain(chainSelector),
	});
}
