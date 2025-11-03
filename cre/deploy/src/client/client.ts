import { Transport, createPublicClient, fallback, http } from "viem";

import { ErrorCode, DomainError } from "../error";
import { findRPCsBySelector } from "./rpcs";
import { findChainBySelector } from "./chains";



export function createFallbackTransport(chainSelector: string): Transport {
	const rpcConfig = findRPCsBySelector(chainSelector);

	if (!rpcConfig || !rpcConfig.rpcUrls || rpcConfig.rpcUrls.length === 0) {
        throw new DomainError(ErrorCode.NO_RPC_PROVIDERS);
	}

	const transportFactories = rpcConfig.rpcUrls.map(url =>
		http(url.startsWith("http") ? url : `https://${url}`, { batch: true }),
	);
	return fallback(transportFactories);
}

export function getPublicClient(chainSelector: string) {
	return createPublicClient({
		transport: createFallbackTransport(chainSelector),
		chain: findChainBySelector(chainSelector),
	});
}
