import { config } from "./config";

export const developmentRpcs: Record<string, any> = {
    "1": {
        rpcs: [
            {
                chainId: "1",
                url: config.localhostRpcUrl,
            },
        ],
    },
    "10": {
        rpcs: [
            {
                chainId: "10",
                url: config.localhostRpcUrl,
            },
        ],
    },
};
