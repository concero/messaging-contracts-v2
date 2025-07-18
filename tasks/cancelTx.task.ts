import type { Address, Chain, Hash } from "viem";
import type { PublicClient, Transaction, WalletClient } from "viem";

import { task } from "hardhat/config";
import type { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { getFallbackClients } from "../utils";

const GAS_BUMP_FACTOR = 1.2;
const handledTxHashes = new Set<Hash>();
const handledNonces = new Set<number>();

type StoredTxInfo = {
	hash: Hash;
	nonce: number;
	from: Address;
	timestamp: string;
	fee: {
		maxFeePerGas?: bigint;
		maxPriorityFeePerGas?: bigint;
		gasPrice?: bigint;
	};
};

const txInfoMap = new Map<Hash, StoredTxInfo>();

function isTargetTransaction(tx: Transaction, target: Address): boolean {
	return tx.from?.toLowerCase() === target.toLowerCase();
}

function getBumpedGasFees(tx: Transaction) {
	if (tx.maxFeePerGas && tx.maxPriorityFeePerGas) {
		return {
			maxFeePerGas: BigInt(Number(tx.maxFeePerGas) * GAS_BUMP_FACTOR),
			maxPriorityFeePerGas: BigInt(Number(tx.maxPriorityFeePerGas) * GAS_BUMP_FACTOR),
		};
	}
	if (tx.gasPrice) {
		return { gasPrice: BigInt(Number(tx.gasPrice) * GAS_BUMP_FACTOR) };
	}
	throw new Error("No gas fee information found in transaction.");
}

async function fetchTransaction(
	client: PublicClient,
	hash: Hash,
	retries = 3,
	delayMs = 500,
): Promise<Transaction | null> {
	for (let attempt = 1; attempt <= retries; attempt++) {
		try {
			const tx = await client.getTransaction({ hash });
			if (tx) return tx;
		} catch (err) {
			if (attempt === retries) {
				console.error(
					`Failed to fetch transaction after ${retries} attempts: ${hash}`,
					err,
				);
				return null;
			}
		}
		await new Promise(res => setTimeout(res, delayMs));
	}
	return null;
}

async function sendCancelTransaction(
	wallet: WalletClient,
	publicClient: PublicClient,
	chain: Chain,
	tx: Transaction,
): Promise<Hash | null> {
	if (!wallet.account) {
		console.error("❌ No account connected with the WalletClient.");
		return null;
	}

	try {
		const gasFees = getBumpedGasFees(tx);

		const request: any = {
			account: wallet.account,
			to: wallet.account.address,
			value: 0n,
			nonce: tx.nonce,
			chain,
			data: "0x",
			...gasFees,
		};

		const txHash = await wallet.sendTransaction(request);
		console.log(`📤 Sent cancel tx for nonce ${tx.nonce}: ${txHash}`);

		console.log(`⏳ Waiting for tx receipt...`);
		const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

		if (receipt.status === "success") {
			console.log(`✅ Cancel tx confirmed in block ${receipt.blockNumber}`);
			handledNonces.add(tx.nonce);
			return txHash;
		} else {
			console.warn(`⚠️ Cancel tx failed on-chain (status = failed)`);
			return null;
		}
	} catch (error) {
		console.error("❌ Error sending or confirming cancel transaction:", error);
		return null;
	}
}

async function processPendingHashes(
	client: PublicClient,
	wallet: WalletClient,
	chain: Chain,
	target: Address,
	hashes: Hash[],
) {
	for (const hash of hashes) {
		console.log(`🔍 Processing pending transaction hash: ${hash}`);
		if (handledTxHashes.has(hash)) continue;
		const tx = await fetchTransaction(client, hash);
		if (!tx) continue;
		if (!isTargetTransaction(tx, target)) continue;
		if (handledNonces.has(tx.nonce)) continue;

		txInfoMap.set(hash, {
			hash,
			nonce: tx.nonce,
			from: tx.from,
			timestamp: new Date().toISOString(),
			fee: {
				maxFeePerGas: tx.maxFeePerGas,
				maxPriorityFeePerGas: tx.maxPriorityFeePerGas,
				gasPrice: tx.gasPrice,
			},
		});
		handledTxHashes.add(hash);
		await sendCancelTransaction(wallet, client, chain, tx);
	}
}

async function cancelSpecificTransaction(
	client: PublicClient,
	wallet: WalletClient,
	chain: Chain,
	txHash: Hash,
): Promise<boolean> {
	try {
		console.log(`🎯 Attempting to cancel specific transaction: ${txHash}`);

		const tx = await fetchTransaction(client, txHash);
		if (!tx) {
			console.error(`❌ Transaction not found: ${txHash}`);
			return false;
		}

		// Check if transaction is still pending
		const receipt = await client.getTransactionReceipt({ hash: txHash });
		if (receipt) {
			console.log(`⚠️ Transaction already confirmed in block ${receipt.blockNumber}`);
			return false;
		}

		// @ts-ignore Chain type mismatch
		const cancelHash = await sendCancelTransaction(wallet, client, chain, tx);
		return cancelHash !== null;
	} catch (error) {
		console.error("❌ Error canceling specific transaction:", error);
		return false;
	}
}

async function findPendingNonce(client: PublicClient, target: Address) {
	try {
		// Get current nonce and pending nonce
		const currentNonce = await client.getTransactionCount({
			address: target,
			blockTag: "latest",
		});
		const pendingNonce = await client.getTransactionCount({
			address: target,
			blockTag: "pending",
		});

		console.log(`📊 Current nonce: ${currentNonce}, pending nonce: ${pendingNonce}`);

		if (currentNonce >= pendingNonce) {
			console.log(`✅ No pending transactions found`);
			return [];
		}
	} catch (error) {
		console.error("❌ Error finding pending transactions:", error);
	}
}

const cancelTransactions = async (specificTxHash?: Hash) => {
	const hre: HardhatRuntimeEnvironment = require("hardhat");
	const network = conceroNetworks[hre.network.name];
	// @ts-ignore Chain type mismatch
	const { publicClient: client, walletClient: wallet } = getFallbackClients(network);

	const myAddress = wallet.account?.address as Address;
	if (!myAddress) throw new Error("No account found on WalletClient.");

	// If specific transaction hash is provided, cancel only that transaction
	if (specificTxHash) {
		const success = await cancelSpecificTransaction(
			client,
			wallet,
			// @ts-ignore Chain type mismatch
			network.viemChain,
			specificTxHash,
		);
		if (success) {
			console.log(`✅ Successfully submitted cancel transaction for ${specificTxHash}`);
		} else {
			console.log(`❌ Failed to cancel transaction ${specificTxHash}`);
		}
		return;
	}

	// Check for existing pending transactions
	await findPendingNonce(client, myAddress);

	console.log(`🚀 Listening with WebSocket for pending txs from: ${myAddress}`);

	client.watchPendingTransactions({
		onTransactions: async (hashes: Hash[]) => {
			// @ts-ignore Client type mismatch
			await processPendingHashes(client, wallet, network.viemChain, myAddress, hashes);
		},
	});

	let lastLog = Date.now();
	while (true) {
		if (Date.now() - lastLog > 30_000) {
			console.log(
				`Info: Tracked ${txInfoMap.size} txs. Cancelled nonces: [${[...handledNonces].sort(
					(a, b) => a - b,
				)}]`,
			);
			lastLog = Date.now();
		}
		await new Promise(res => setTimeout(res, 2500));
	}
};

task("cancel-tx", "Cancel stuck self transactions in mempool")
	.addOptionalParam("hash", "Specific transaction hash to cancel", undefined)
	.setAction(async taskArgs => {
		try {
			const txHash = taskArgs.hash as Hash | undefined;
			await cancelTransactions(txHash);
		} catch (e) {
			console.error(e);
			process.exit(1);
		}
	});

export default {};
