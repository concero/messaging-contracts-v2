import {Runtime} from "@chainlink/cre-sdk";
import {sha256} from "viem";

import testnetChainsRPCs from "@concero/rpcs/output/testnet.json";
import mainnetChainsRPCs from "@concero/rpcs/output/mainnet.json";
import testnetDataNetworks from "@concero/v2-networks/networks/testnet.json";
import mainnetDataNetworks from "@concero/v2-networks/networks/mainnet.json";

import {DomainError, ErrorCode, GlobalContext} from "../helpers";

const chainsOptions = { ...mainnetChainsRPCs, ...testnetChainsRPCs };
const currentCheckSum = sha256(Buffer.from(JSON.stringify(chainsOptions)))

const networksOptions = { ...mainnetDataNetworks, ...testnetDataNetworks };
const networkCheckSum = sha256(Buffer.from(JSON.stringify(networksOptions)))


type Options = {
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

export const chainSelectorToChainOptions: Record<number, Options> = {};

export class ChainsManager {
    static enrichOptions() {
        Object.values(chainsOptions).forEach((i) => {
            if (i && i.rpcUrls) {
                chainSelectorToChainOptions[i.chainSelector] = {
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
                chainSelectorToChainOptions[i.chainSelector] = {
                    ...chainSelectorToChainOptions?.[i.chainSelector],
                    name: i.name,
                    nativeCurrency: i.nativeCurrency,
                    finalityConfirmations: i.finalityConfirmations,
                };
            }
        });
    }

    static validateOptions(runtime: Runtime<GlobalContext>): void {
        const originalChainsChecksum = runtime.getSecret({id: 'CHAINS_CONFIG_HASHSUM'}).result().value
        const originalNetworksChecksum = runtime.getSecret({id: 'NETWORKS_CONFIG_HASHSUM'}).result().value
        if (currentCheckSum === originalChainsChecksum){
            throw new Error('Invalid chains checksum');
        }
        if (networkCheckSum === originalNetworksChecksum){
            throw new Error('Invalid networks checksum');
        }
    }

    static getOptionsBySelector(chainSelector: number): Options {
        const chainOption = chainSelectorToChainOptions[chainSelector]

        if (!chainOption) {
            throw new DomainError(ErrorCode.NO_CHAIN_DATA, "Chain not found");
        }

        return chainOption;
    }


}
