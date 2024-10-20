import { ConceroNetworkType } from "../types/ConceroNetwork";

export function getPrivateKey(chainType: ConceroNetworkType, accountType: "proxyDeployer" | "deployer") {
    let deployerPrefix;
    switch (accountType) {
        case "proxyDeployer":
            deployerPrefix = "PROXY_DEPLOYER";
            break;
        case "deployer":
            deployerPrefix = "DEPLOYER";
            break;
        default:
            throw new Error(`Unknown account type: ${accountType}`);
    }

    const envKey = `${chainType.toUpperCase()}_${deployerPrefix}_PRIVATE_KEY`;
    return process.env[envKey];
}
