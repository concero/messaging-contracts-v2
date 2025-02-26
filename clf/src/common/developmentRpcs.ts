import { config } from "./config";

export const developmentRpcs: Record<string, any> = {
    "1": {
        rpcs: [
            {
                chainId: "1",
                url: config.localhostRpcUrl,
                responseTime: 160,
            },
        ],
    },
};
