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

export const config = {
	isDevelopment: isDevelopment(),
	localhostRpcUrl: getLocalhostRpcUrl(),
};
