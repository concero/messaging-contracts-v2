// Network-specific gas configuration
export const networkGasConfig: Record<string, { multiplier: number }> = {
	// Mantle networks typically need 1000x more gas
	"5000": { multiplier: 1000 },
	"5003": { multiplier: 1000 },
};

// Gas fee configuration by network type for ConceroRouter
export const gasFeeConfig = {
	testnet: {
		baseChainSelector: 421614, // Arbitrum Sepolia
		submitMsgGasOverhead: 150000, // ConceroRouter::submitMessageReport (dst)
		vrfMsgReportRequestGasOverhead: 330000, // ConceroVerifier::requestMessageReport
		clfCallbackGasOverhead: 240000, // CLF::FunctionCoordinator::transmit + CLF::FunctionRouter::_callback
	},
	mainnet: {
		baseChainSelector: 42161, // Arbitrum One
		submitMsgGasOverhead: 150000,
		vrfMsgReportRequestGasOverhead: 330000,
		clfCallbackGasOverhead: 240000,
	},
};

// Gas fee configuration for ConceroVerifier
export const gasFeeConfigVerifier = {
	vrfMsgReportRequestGasOverhead: 330000, // ConceroVerifier::requestMessageReport
	clfGasPriceOverEstimationBps: 10000, // Over estimation for gas price in bps (x2), original CLF value is 40000 (x5)
	clfCallbackGasOverhead: 240000, // CLF::FunctionCoordinator::transmit + CLF::FunctionRouter::_callback
	clfCallbackGasLimit: 50000, // CLF callback gas limit from our side (actual value about 40k)
};
