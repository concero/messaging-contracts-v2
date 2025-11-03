import { createPublicClient, fallback, http, Transport } from "viem";

import { DomainError, ErrorCode } from "../error";
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
    const chain = findChainBySelector(chainSelector)
    if (!chain) throw new DomainError(ErrorCode.INVALID_CHAIN_DATA)
	return createPublicClient({
		transport: createFallbackTransport(chainSelector),
        chain,
	});
}
