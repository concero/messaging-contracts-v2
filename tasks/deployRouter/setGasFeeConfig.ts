import { ConceroNetwork } from "@concero/contract-utils";

import { ProxyEnum } from "../../constants";
import { conceroNetworks } from "../../constants";
import { getEnvAddress, getFallbackClients, log } from "../../utils";

const NETWORK_GAS_CONFIG: Record<string, { multiplier: number }> = {
	// Mantle networks typically need 1000x more gas
	"5000": { multiplier: 1000 },
	"5003": { multiplier: 1000 },
};

export async function setGasFeeConfig(network: ConceroNetwork) {
	const { abi: conceroRouterAbi } = await import(
		"../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);
	const { publicClient, walletClient } = getFallbackClients(network);
	const [conceroRouterAddress] = getEnvAddress(ProxyEnum.routerProxy, network.name);

	// Get network type from conceroNetworks like in deployment
	const chain = conceroNetworks[network.name as keyof typeof conceroNetworks];
	const { type: networkType } = chain;
	const prefix = networkType === "testnet" ? "TESTNET" : "MAINNET";

	// Get gas multiplier for special networks (like Mantle)
	const gasMultiplier = NETWORK_GAS_CONFIG[network.chainId.toString()]?.multiplier || 1;

	// Get parameters from environment variables
	const baseChainSelector = process.env[`${prefix}_BASE_CHAIN_SELECTOR`];
	const submitMsgGasOverhead = process.env[`${prefix}_SUBMIT_MSG_GAS_OVERHEAD`];
	const vrfMsgReportRequestGasLimit = process.env[`${prefix}_VRF_MSG_REPORT_REQUEST_GAS_LIMIT`];
	const vrfCallbackGasLimit = process.env[`${prefix}_VRF_CALLBACK_GAS_LIMIT`];

	// Validate environment variables
	if (
		!baseChainSelector ||
		!submitMsgGasOverhead ||
		!vrfMsgReportRequestGasLimit ||
		!vrfCallbackGasLimit
	) {
		log(
			`Missing required environment variables for ${prefix}. Required: ${prefix}_BASE_CHAIN_SELECTOR, ${prefix}_SUBMIT_MSG_GAS_OVERHEAD, ${prefix}_VRF_MSG_REPORT_REQUEST_GAS_LIMIT, ${prefix}_VRF_CALLBACK_GAS_LIMIT`,
			"setGasFeeConfig",
			network.name,
		);
		return;
	}

	try {
		// Convert string values to appropriate types and apply gas multiplier
		const baseChainSelectorNum = parseInt(baseChainSelector);
		const submitMsgGasOverheadNum = parseInt(submitMsgGasOverhead) * gasMultiplier;
		const vrfMsgReportRequestGasLimitNum =
			parseInt(vrfMsgReportRequestGasLimit) * gasMultiplier;
		const vrfCallbackGasLimitNum = parseInt(vrfCallbackGasLimit) * gasMultiplier;

		log(
			`Setting gas fee config for chainId ${network.chainId} (multiplier: ${gasMultiplier}x): baseChainSelector=${baseChainSelectorNum}, submitMsgGasOverhead=${submitMsgGasOverheadNum}, vrfMsgReportRequestGasLimit=${vrfMsgReportRequestGasLimitNum}, vrfCallbackGasLimit=${vrfCallbackGasLimitNum}`,
			"setGasFeeConfig",
			network.name,
		);

		const setGasFeeConfigHash = await walletClient.writeContract({
			account: walletClient.account!,
			address: conceroRouterAddress,
			abi: conceroRouterAbi,
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
				`Gas fee config set successfully. Hash: ${setGasFeeConfigHash}`,
				"setGasFeeConfig",
				network.name,
			);
		} else {
			log(
				`Set gas fee config reverted ${setGasFeeConfigHash}`,
				"setGasFeeConfig",
				network.name,
			);
		}
	} catch (error) {
		log((error as Error).message, "setGasFeeConfig", network.name);
	}
}
