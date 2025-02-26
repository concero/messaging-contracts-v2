export const config = {
    isDevelopment: process?.env?.CONCERO_CLF_DEVELOPMENT === "true",
    localhostRpcUrl: process?.env?.LOCALHOST_RPC_URL,
};
