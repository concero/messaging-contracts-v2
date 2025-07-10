function isDevelopment() {
	try {
		return secrets?.CONCERO_CLF_DEVELOPMENT === "true";
	} catch {
		return false;
	}
}

function getLocalhostRpcUrl() {
	try {
		return secrets?.LOCALHOST_RPC_URL;
	} catch {
		return undefined;
	}
}

// Network-specific gas configuration
export const networkGasConfig: Record<string, { multiplier: number }> = {
	// Mantle networks typically need 1000x more gas
	"5000": { multiplier: 1000 },
	"5003": { multiplier: 1000 },
};

// Gas fee configuration by network type
export const gasFeeConfig = {
	testnet: {
		baseChainSelector: 421614,  // Arbitrum Sepolia
		submitMsgGasOverhead: 150000, // ConceroRouter::submitMessageReport (dst)
		vrfMsgReportRequestGasLimit: 330000, // Operator::requestMessageReport
		vrfCallbackGasLimit: 240000, // CLF::FunctionCoordinator::transmit + CLF::FunctionRouter::_callback
	},
	mainnet: {
		baseChainSelector: 42161, // Arbitrum One
		submitMsgGasOverhead: 150000,
		vrfMsgReportRequestGasLimit: 330000,
		vrfCallbackGasLimit: 240000,
	},
};

export const gasFeeConfigVerifier = {
	vrfMsgReportRequestGasOverhead: 330000,
	clfGasPriceOverEstimationBps: 40000,
	clfCallbackGasOverhead: 240000,
	clfCallbackGasLimit: 100000,
};

export const config = {
	isDevelopment: isDevelopment(),
	localhostRpcUrl: getLocalhostRpcUrl(),
	// @dev TODO: remove this hardcoded value. pass chain id to clf to initialize isTestnet variable
	verifierChainSelector: "421614",
	gasFeeConfig,
	networkGasConfig,
};
