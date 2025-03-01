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
    "2": {
        rpcs: [
            {
                chainId: "2",
                url: config.localhostRpcUrl,
            },
        ],
    },
};
