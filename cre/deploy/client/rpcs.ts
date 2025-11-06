import testnetChains from "@concero/rpcs/output/testnet.json";
import testnetNetworks from "@concero/v2-networks/networks/testnet.json";


export type RpcConfig = {
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

export const chainSelectorToRpcConfig: Record<number, RpcConfig> = {};

Object.entries(testnetNetworks as unknown as Record<number, NetworkData>).forEach(([networkName, networkData]) => {
	const chainData = (testnetChains as any)[networkName] as ChainData;

	if (chainData && chainData.rpcUrls) {
        chainSelectorToRpcConfig[networkData.chainSelector] = {
			chainSelector: networkData.chainSelector,
			chainId: networkData.chainId,
			rpcUrls: chainData.rpcUrls,
			finalityConfirmations: networkData.finalityConfirmations,
		};
	}
});


export function findRPCsBySelector(chainSelector: number): Pick<RpcConfig, 'rpcUrls'> {
    return chainSelectorToRpcConfig[chainSelector];
}
