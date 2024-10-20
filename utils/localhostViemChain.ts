import { defineChain } from "viem";

export const localhostViemChain = defineChain({
    id: Number(process.env.LOCALHOST_FORK_CHAIN_ID),
    name: "localhost",
    nativeCurrency: {
        decimals: 18,
        name: "eth",
        symbol: "eth",
    },
    rpcUrls: {
        default: { http: [process.env.LOCALHOST_RPC_URL] },
    },
    testnet: true,
});

export const hardhatViemChain = defineChain({
    id: Number(process.env.HARDHAT_CHAIN_ID),
    name: "hardhat",
    nativeCurrency: {
        decimals: 18,
        name: "eth",
        symbol: "eth",
    },
    rpcUrls: {
        default: { http: [process.env.HARDHAT_RPC_URL] },
    },
    testnet: true,
});
