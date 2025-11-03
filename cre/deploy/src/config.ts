export function isDevelopment() {
	try {
		return secrets?.CONCERO_CLF_DEVELOPMENT === "true";
	} catch {
		return false;
	}
}

export function getLocalhostRpcUrl() {
	try {
		return secrets?.LOCALHOST_RPC_URL;
	} catch {
		return undefined;
	}
}

export const config = {
	isDevelopment: isDevelopment(),
	localhostRpcUrl: getLocalhostRpcUrl(),
	// @dev TODO: remove this hardcoded value. pass chain id to clf to initialize isTestnet variable
	verifierChainSelector: "421614",
};
