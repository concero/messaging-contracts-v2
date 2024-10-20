import { privateKeyToAccount } from "viem/accounts";
import { Chain, createPublicClient, createWalletClient, fallback, http } from "viem";
import type { PrivateKeyAccount } from "viem/accounts/types";
import { WalletClient } from "viem/clients/createWalletClient";
import { PublicClient } from "viem/clients/createPublicClient";
import { urls } from "../constants";
import { ConceroNetwork, ConceroNetworkType } from "../types/ConceroNetwork";
import { getEnvVar } from "./getEnvVar";

export function getClients(
    viemChain: Chain,
    url: string | undefined,
    account?: PrivateKeyAccount = privateKeyToAccount(`0x${process.env.DEPLOYER_PRIVATE_KEY}`),
): {
    walletClient: WalletClient;
    publicClient: PublicClient;
    account: PrivateKeyAccount;
} {
    const publicClient = createPublicClient({ transport: http(url), chain: viemChain });
    const walletClient = createWalletClient({ transport: http(url), chain: viemChain, account });

    return { walletClient, publicClient, account };
}

export function getFallbackClients(
    chain: ConceroNetwork,
    account?: PrivateKeyAccount,
): {
    walletClient: WalletClient;
    publicClient: PublicClient;
    account: PrivateKeyAccount;
} {
    if (!account) {
        account =
            chain.type === "mainnet"
                ? privateKeyToAccount(`0x${process.env.DEPLOYER_PRIVATE_KEY}`)
                : privateKeyToAccount(`0x${process.env.TEST_DEPLOYER_PRIVATE_KEY}`);
    }

    const { viemChain, name } = chain;
    const transport = fallback(urls[name].map(url => http(url)));

    const publicClient = createPublicClient({ transport, chain: viemChain });
    const walletClient = createWalletClient({ transport, chain: viemChain, account });

    return { walletClient, publicClient, account };
}

export function getViemAccount(chainType: ConceroNetworkType, accountType: "proxyDeployer" | "deployer") {
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
    return privateKeyToAccount(`0x${getEnvVar(envKey)}`);
}
