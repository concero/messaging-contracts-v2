import { type Chain, defineChain } from "viem";

export function findChainBySelector(chainSelector: number): Chain {
    return defineChain({
        id: chainSelector,
        nativeCurrency: {
            decimals: 18,
            name: "Ether",
            symbol: "ETH",
        },
        rpcUrls: {
            default: {
                http: ["https://arbitrum-sepolia.gateway.tenderly.co"],
            },
        },
    } as any) as Chain;
}
