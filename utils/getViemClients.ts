import {
	Chain,
	type TestClient,
	createPublicClient,
	createTestClient,
	createWalletClient,
	fallback,
	http,
	publicActions,
	walletActions,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";
import type { PrivateKeyAccount } from "viem/accounts/types";
import { PublicClient } from "viem/clients/createPublicClient";
import { WalletClient } from "viem/clients/createWalletClient";

import { urls } from "../constants";
import { ConceroNetwork, ConceroNetworkType } from "../types/ConceroNetwork";
import { getWallet } from "./getWallet";
import { localhostViemChain } from "./localhostViemChain";

function getClients(
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

export type ExtendedTestClient = TestClient & WalletClient & PublicClient;

function getTestClient(account: PrivateKeyAccount): ExtendedTestClient {
	const testClient = createTestClient({
		chain: localhostViemChain,
		mode: "hardhat",
		transport: http(),
		account,
	})
		.extend(publicActions)
		.extend(walletActions);

	return testClient;
}

function getFallbackClients(
	chain: ConceroNetwork,
	account?: PrivateKeyAccount,
): {
	walletClient: WalletClient;
	publicClient: PublicClient;
	account: PrivateKeyAccount;
} {
	if (!account) {
		switch (chain.type) {
			case "mainnet":
				account = privateKeyToAccount(`0x${process.env.MAINNET_DEPLOYER_PRIVATE_KEY}`);
				break;
			case "testnet":
				account = privateKeyToAccount(`0x${process.env.TESTNET_DEPLOYER_PRIVATE_KEY}`);
				break;
			case "localhost":
				account = privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`);
				break;
			default:
				throw new Error(`Unsupported chain type: ${chain.type}`);
		}
	}

	const { viemChain, name } = chain;

	const transport = fallback(urls[name].map(url => http(url)));
	const publicClient = createPublicClient({ transport, chain: viemChain });
	const walletClient = createWalletClient({ transport, chain: viemChain, account });

	return { walletClient, publicClient, account };
}

function getViemAccount(chainType: ConceroNetworkType, accountType: "proxyDeployer" | "deployer") {
	return privateKeyToAccount(`0x${getWallet(chainType, accountType, "privateKey")}`);
}

export { getClients, getFallbackClients, getTestClient, getViemAccount };
