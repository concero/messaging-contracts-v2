import { Transport, createPublicClient, fallback, http } from "viem";

import { viemChains } from "../messageReport/constants/viemChains";
import { config } from "./config";
import { developmentRpcs } from "./developmentRpcs";
import { handleError } from "./errorHandler";
import { ErrorType } from "./errorType";
import { healthyRPCs } from "./healthyRPCs";

function createCustomTransport(url: string, chainIdHex: string): Transport {
	// return createTransport({
	//     name: "customTransport",
	//     key: "custom",
	//     type: "http",
	//     retryCount: CONFIG.VIEM.RETRY_COUNT,
	//     retryDelay: CONFIG.VIEM.RETRY_DELAY,
	//     request: async ({ method, params }) => {
	//         if (method === "eth_chainId") return { jsonrpc: "2.0", id: 1, result: chainIdHex };
	//         const response = await fetch(url, {
	//             method: "POST",
	//             headers: { "Content-Type": "application/json" },
	//             body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
	//         });
	//         const result = await response.json();
	//         if (Array.isArray(result)) {
	//             return [result];
	//         }
	//         return result;
	//     },
	// });
	// return custom({
	//     retryCount: CONFIG.VIEM.RETRY_COUNT,
	//     retryDelay: CONFIG.VIEM.RETRY_DELAY,
	//     async request({ method, params }) {
	//         if (method === "eth_chainId") return { jsonrpc: "2.0", id: 1, result: chainIdHex };
	//         const response = await fetch(url, {
	//             method: "POST",
	//             headers: { "Content-Type": "application/json" },
	//             body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
	//         });
	//         const result = await response.json();
	//         // if (Array.isArray(result)) {
	//         //     return [result];
	//         // }
	//         return [result];
	//     },
	// });

	return http(url, { batch: true });
}

export function createFallbackTransport(chainSelector: string): Transport {
	const chainConfig = config.isDevelopment ? developmentRpcs[chainSelector] : healthyRPCs[chainSelector];
	if (!chainConfig) {
		handleError(ErrorType.INVALID_CHAIN);
	}

	if (!chainConfig.rpcs[0]) {
		handleError(ErrorType.INVALID_RPC);
	}

	const chainIdHex = `0x${parseInt(chainConfig.rpcs[0].chainId, 10).toString(16)}`;

	const transportFactories = chainConfig.rpcs.map(rpc => createCustomTransport(rpc.url, chainIdHex));

	return fallback(transportFactories);
}

export function getPublicClient(chainSelector: string) {
	const chainConfig = config.isDevelopment ? developmentRpcs[chainSelector] : healthyRPCs[chainSelector];

	if (!chainConfig || !chainConfig.rpcs.length) {
		handleError(ErrorType.NO_RPC_PROVIDERS);
	}

	return createPublicClient({
		transport: createFallbackTransport(chainSelector),
		chain: viemChains[chainSelector],
	});
}
