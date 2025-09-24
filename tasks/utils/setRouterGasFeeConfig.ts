import { ProxyEnum } from "../../constants";
import { conceroNetworks } from "../../constants";
import { gasFeeConfig, networkGasConfig } from "../../constants/gasConfig";
import {
	ConceroHardhatNetwork,
	ConceroLocalNetwork,
	ConceroNetwork,
} from "../../types/ConceroNetwork";
import { getEnvAddress, getFallbackClients, log } from "../../utils";

export type AnyNetwork = ConceroNetwork | ConceroLocalNetwork | ConceroHardhatNetwork;

export async function setRouterGasFeeConfig(network: AnyNetwork) {
	const { abi } = await import(
		"../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	const { publicClient, walletClient } = getFallbackClients(network);

	// Get the router contract address
	const [contractAddress] = getEnvAddress(ProxyEnum.routerProxy, network.name);

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
		const vrfMsgReportRequestGasOverheadNum =
			config.vrfMsgReportRequestGasOverhead * gasMultiplier;
		const clfCallbackGasOverheadNum = config.clfCallbackGasOverhead * gasMultiplier;

		log(
			`Setting router gas fee config on chainId ${network.chainId} (multiplier: ${gasMultiplier}x): baseChainSelector=${baseChainSelectorNum}, submitMsgGasOverhead=${submitMsgGasOverheadNum}, vrfMsgReportRequestGasOverhead=${vrfMsgReportRequestGasOverheadNum}, clfCallbackGasOverhead=${clfCallbackGasOverheadNum}`,
			"setRouterGasFeeConfig",
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
				vrfMsgReportRequestGasOverheadNum,
				clfCallbackGasOverheadNum,
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
				`Router gas fee config set successfully. Hash: ${setGasFeeConfigHash}`,
				"setRouterGasFeeConfig",
				network.name,
			);
		} else {
			log(
				`Set router gas fee config reverted: ${setGasFeeConfigHash}`,
				"setRouterGasFeeConfig",
				network.name,
			);
		}
	} catch (error) {
		log(
			`Error setting router gas fee config: ${(error as Error).message}`,
			"setRouterGasFeeConfig",
			network.name,
		);
	}
}
