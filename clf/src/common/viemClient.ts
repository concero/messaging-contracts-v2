import { createPublicClient, Transport, createTransport, fallback } from "viem";
import healthyRpcs from "./healthy-rpcs.json";

import { CONFIG } from "../messageReport/constants/config";
import { ErrorType } from "../messageReport/constants/errorTypes";
import { handleError } from "./errorHandler";

function createCustomTransport(url: string, chainIdHex: string): Transport {
    return createTransport({
        name: "customTransport",
        key: "custom",
        type: "http",
        retryCount: CONFIG.VIEM.RETRY_COUNT,
        retryDelay: CONFIG.VIEM.RETRY_DELAY,
        request: async ({ method, params }) => {
            if (method === "eth_chainId") {
                return { jsonrpc: "2.0", id: 1, result: chainIdHex };
            }
            const response = await fetch(url, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ jsonrpc: "2.0", id: 1, method, params }),
            });
            const result = await response.json();
            return result;
        },
    });
}

export function createFallbackTransport(chainSelector: string): Transport {
    const chainConfig = healthyRpcs[chainSelector];
    if (!chainConfig) {
        handleError(ErrorType.INVALID_CHAIN);
    }

    if (!chainConfig.rpcs[0]) {
        handleError(ErrorType.INVALID_RPC);
    }

    const chainIdHex = `0x${parseInt(chainConfig.rpcs[0].chainId, 10).toString(16)}`;
    const transports = chainConfig.rpcs.map(rpc => createCustomTransport(rpc.url, chainIdHex));
    return fallback(transports);
}

export function getPublicClient(chainSelector: string) {
    const chainConfig = healthyRpcs[chainSelector];
    if (!chainConfig || !chainConfig.rpcs.length) {
        handleError(ErrorType.NO_RPC_PROVIDERS);
    }

    const chainIdHex = `0x${parseInt(chainConfig.rpcs[0].chainId, 10).toString(16)}`;
    const defaultRpcUrl = chainConfig.rpcs[0].url;

    return createPublicClient({
        transport: createFallbackTransport(chainSelector),
        chain: {
            id: parseInt(chainIdHex, 16),
            name: chainSelector,
            network: chainSelector,
            nativeCurrency: {
                name: "Ether",
                symbol: "ETH",
                decimals: 18,
            },
            rpcUrls: {
                default: defaultRpcUrl,
            },
        },
    });
}
