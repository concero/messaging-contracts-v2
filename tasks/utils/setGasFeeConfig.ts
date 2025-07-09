import { gasFeeConfig, networkGasConfig } from "../../clf/src/common/config";
import { ProxyEnum } from "../../constants";
import { conceroNetworks } from "../../constants";
import {
	ConceroHardhatNetwork,
	ConceroLocalNetwork,
	ConceroNetwork,
} from "../../types/ConceroNetwork";
import { IProxyType } from "../../types/deploymentVariables";
import { getEnvAddress, getFallbackClients, log } from "../../utils";

export type AnyNetwork = ConceroNetwork | ConceroLocalNetwork | ConceroHardhatNetwork;

export async function setGasFeeConfig(network: AnyNetwork, proxyType: IProxyType) {
	// Import the appropriate contract ABI based on type
	const { abi } = await import(
		proxyType === ProxyEnum.routerProxy
			? "../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
			: "../../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const { publicClient, walletClient } = getFallbackClients(network);

	// Get the appropriate contract address based on type
	const [contractAddress] = getEnvAddress(proxyType, network.name);

	// Get network type from conceroNetworks
	const chain = conceroNetworks[network.name as keyof typeof conceroNetworks];
	const { type: networkType } = chain;

	// Get gas configuration based on network type
	const config = networkType === "testnet" ? gasFeeConfig.testnet : gasFeeConfig.mainnet;

	// Get gas multiplier for special networks (like Mantle)
	const gasMultiplier = networkGasConfig[network.chainId.toString()]?.multiplier || 1;

	try {
		// Apply gas multiplier to the configuration values
		const baseChainSelectorNum = config.baseChainSelector;
		const submitMsgGasOverheadNum = config.submitMsgGasOverhead * gasMultiplier;
		const vrfMsgReportRequestGasLimitNum = config.vrfMsgReportRequestGasLimit * gasMultiplier;
		const vrfCallbackGasLimitNum = config.vrfCallbackGasLimit * gasMultiplier;

		log(
			`Setting gas fee config for ${proxyType} on chainId ${network.chainId} (multiplier: ${gasMultiplier}x): baseChainSelector=${baseChainSelectorNum}, submitMsgGasOverhead=${submitMsgGasOverheadNum}, vrfMsgReportRequestGasLimit=${vrfMsgReportRequestGasLimitNum}, vrfCallbackGasLimit=${vrfCallbackGasLimitNum}`,
			"setGasFeeConfig",
			network.name,
		);

		const setGasFeeConfigHash = await walletClient.writeContract({
			account: walletClient.account!,
			address: contractAddress,
			abi: abi,
			functionName: "setGasFeeConfig",
			args: [
				baseChainSelectorNum,
				submitMsgGasOverheadNum,
				vrfMsgReportRequestGasLimitNum,
				vrfCallbackGasLimitNum,
			],
			chain: undefined,
		});

		const setGasFeeConfigStatus = (
			await publicClient.waitForTransactionReceipt({
				hash: setGasFeeConfigHash,
			})
		).status;

		if (setGasFeeConfigStatus === "success") {
			log(
				`Gas fee config set successfully for ${proxyType}. Hash: ${setGasFeeConfigHash}`,
				"setGasFeeConfig",
				network.name,
			);
		} else {
			log(
				`Set gas fee config reverted for ${proxyType}: ${setGasFeeConfigHash}`,
				"setGasFeeConfig",
				network.name,
			);
		}
	} catch (error) {
		log(
			`Error setting gas fee config for ${proxyType}: ${(error as Error).message}`,
			"setGasFeeConfig",
			network.name,
		);
	}
}
