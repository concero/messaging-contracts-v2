import { ConceroNetworkType } from "../types/ConceroNetwork";

export function getWallet(
    chainType: ConceroNetworkType,
    accountType: "proxyDeployer" | "deployer" | "operator",
    walletType: "privateKey" | "address",
) {
    let prefix;
    let walletKey;
    switch (accountType) {
        case "proxyDeployer":
            prefix = "PROXY_DEPLOYER";
            break;
        case "deployer":
            prefix = "DEPLOYER";
            break;
        case "operator":
            prefix = "OPERATOR";
            break;
        default:
            throw new Error(`Unknown account type: ${accountType}`);
    }

    switch (walletType) {
        case "privateKey":
            walletKey = "PRIVATE_KEY";
            break;
        case "address":
            walletKey = "ADDRESS";
            break;
        default:
            throw new Error(`Unknown wallet type: ${walletType}`);
    }

    // Determine the environment variable key based on the wallet type
    const envKey = `${chainType.toUpperCase()}_${prefix}_${walletKey}`;
    const walletValue = process.env[envKey];

    if (!walletValue) {
        throw new Error(`Environment variable ${envKey} is not set.`);
    }

    return walletValue;
}
