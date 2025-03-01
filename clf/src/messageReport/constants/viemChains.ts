import { defineChain, type Chain } from "viem";
import { base, mainnet } from "viem/chains";
import { config } from "../../common/config";

const localhostChain = defineChain({
    id: 1,
    name: "localhost",
    nativeCurrency: {
        decimals: 18,
        name: "Ether",
        symbol: "ETH",
    },
    rpcUrls: {
        default: {
            http: config.localhostRpcUrl,
        },
    },
});

const localhostChains: Record<number, Chain> = {
    1: localhostChain,
    2: localhostChain,
};

const mainnetChains: Record<number, Chain> = {
    1: mainnet,
    8453: base,
};

export const viemChains = config.isDevelopment ? localhostChains : mainnetChains;
