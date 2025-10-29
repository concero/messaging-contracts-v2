import testnetNetworks from "@concero/v2-networks/networks/testnet.json";

import { mock as testnetChains } from "./MockRpc";

export interface RpcConfig {
	rpcUrls: string[];
	chainSelector: number;
	chainId: string;
	finalityConfirmations: number;
}

type ChainData = {
	rpcUrls: string[];
	chainSelector: number;
	chainId: string;
};

type NetworkData = {
	chainId: string;
	chainSelector: number;
	finalityConfirmations: number;
};

const rpcConfigs: Record<number, RpcConfig> = {};

Object.entries(testnetNetworks as Record<string, NetworkData>).forEach(
	([networkName, networkData]) => {
		const chainData = (testnetChains as any)[networkName] as ChainData;

		if (chainData && chainData.rpcUrls) {
			rpcConfigs[networkData.chainSelector] = {
				chainSelector: networkData.chainSelector,
				chainId: networkData.chainId,
				rpcUrls: chainData.rpcUrls,
				finalityConfirmations: networkData.finalityConfirmations,
			};
		}
	},
);

export { rpcConfigs };
