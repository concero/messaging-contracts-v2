import mainnetChains from "@concero/rpcs/output/mainnet.json";
import testnetChains from "@concero/rpcs/output/testnet.json";
import mainnetNetworks from "@concero/v2-networks/networks/mainnet.json";
import testnetNetworks from "@concero/v2-networks/networks/testnet.json";

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
	chainId: number;
	chainSelector: number;
	finalityConfirmations: number;
};

const rpcConfigs: Record<number, RpcConfig> = {};

Object.entries(mainnetNetworks as Record<string, NetworkData>).forEach(([networkName, networkData]) => {
	const chainId = networkData.chainId.toString();
	const chainData = (mainnetChains as any)[chainId] as ChainData;

	if (chainData && chainData.rpcUrls) {
		rpcConfigs[networkData.chainSelector] = {
			chainSelector: networkData.chainSelector,
			chainId: chainId,
			rpcUrls: chainData.rpcUrls,
			finalityConfirmations: networkData.finalityConfirmations,
		};
	}
});

Object.entries(testnetNetworks as Record<string, NetworkData>).forEach(([networkName, networkData]) => {
	const chainId = networkData.chainId.toString();
	const chainData = (testnetChains as any)[chainId] as ChainData;

	if (chainData && chainData.rpcUrls) {
		rpcConfigs[networkData.chainSelector] = {
			chainSelector: networkData.chainSelector,
			chainId: chainId,
			rpcUrls: chainData.rpcUrls,
			finalityConfirmations: networkData.finalityConfirmations,
		};
	}
});

export { rpcConfigs };
export default rpcConfigs;
