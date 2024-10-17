import { type CNetwork } from "../types/CNetwork";
import { cNetworks } from "./cNetworks";
import { type ConceroChains } from "../types/chains";

export const liveChains: CNetwork[] = [
    cNetworks.baseSepolia,
    cNetworks.arbitrumSepolia,
    cNetworks.avalancheFuji,
    // cNetworks.optimismSepolia,
    // cNetworks.polygonAmoy,
];

// export const liveChains: CNetwork[] = [cNetworks.polygon, cNetworks.base, cNetworks.arbitrum, cNetworks.avalanche];

export const conceroChains: ConceroChains = {
    testnet: {
        parentPool: [cNetworks.baseSepolia],
        childPool: [cNetworks.arbitrumSepolia, cNetworks.avalancheFuji],
        infra: [cNetworks.arbitrumSepolia, cNetworks.avalancheFuji, cNetworks.baseSepolia],
    },
    mainnet: {
        parentPool: [cNetworks.base],
        childPool: [cNetworks.polygon, cNetworks.arbitrum, cNetworks.avalanche],
        infra: [cNetworks.polygon, cNetworks.arbitrum, cNetworks.avalanche, cNetworks.base],
    },
};

export const testnetChains: CNetwork[] = Array.from(
    new Set([...conceroChains.testnet.parentPool, ...conceroChains.testnet.childPool, ...conceroChains.testnet.infra]),
);

export const mainnetChains: CNetwork[] = Array.from(
    new Set([...conceroChains.mainnet.parentPool, ...conceroChains.mainnet.childPool, ...conceroChains.mainnet.infra]),
);
