import testnetChainsRPCs from "@concero/rpcs/output/testnet.json";
import mainnetChainsRPCs from "@concero/rpcs/output/mainnet.json";
import testnetDataNetworks from "@concero/v2-networks/networks/testnet.json";
import mainnetDataNetworks from "@concero/v2-networks/networks/mainnet.json";

import { DomainError, ErrorCode } from "../error";

export const chainsOptions = { ...mainnetChainsRPCs, ...testnetChainsRPCs };
export const networksOptions = { ...mainnetDataNetworks, ...testnetDataNetworks };

export type ChainOptions = {
    id: number
    name: string
    selector: number
    rpcUrls: string[];
    nativeCurrency?: {
        name: string,
        symbol: string,
        decimals: number
    }
	finalityConfirmations: number;
}

export const chainSelectorToRpcConfig: Record<number, ChainOptions> = {};

Object.values(chainsOptions).forEach((i) => {
    if (i && i.rpcUrls) {
        chainSelectorToRpcConfig[i.chainSelector] = {
            id: Number(i.chainId),
            name: 'unknown chain',
            selector: i.chainSelector,
            rpcUrls: i.rpcUrls,
            finalityConfirmations: 0,
        };
    }
});
Object.values(networksOptions).forEach((i) => {
    if (i && i.rpcUrls) {
        chainSelectorToRpcConfig[i.chainSelector] = {
            ...chainSelectorToRpcConfig?.[i.chainSelector],
            name: i.name,
            nativeCurrency: i.nativeCurrency,
            finalityConfirmations: i.finalityConfirmations,
        };
    }
});


export function getChainOptionsByChainSelector(chainSelector: number): ChainOptions {
    const chainOption = chainSelectorToRpcConfig[chainSelector]

    if (!chainOption) {
        throw new DomainError(ErrorCode.NO_CHAIN_DATA, "Chain not found");
    }

    return chainOption;
}
