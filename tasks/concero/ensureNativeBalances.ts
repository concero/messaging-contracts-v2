import { task } from "hardhat/config";

import readline from "readline";

import { mainnetNetworks, testnetNetworks } from "@concero/contract-utils";
import { formatEther, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import { viemReceiptConfig } from "../../constants";
import { type BalanceInfo } from "../../types/BalanceInfo";
import { type ConceroNetwork } from "../../types/ConceroNetwork";
import { err, getEnvVar, getFallbackClients, log } from "../../utils";

const DEFAULT_TARGET_BALANCE = parseEther("0.001");

const MAINNET_DEPLOYER_PRIVATE_KEY = getEnvVar("MAINNET_DEPLOYER_PRIVATE_KEY");
const TESTNET_DEPLOYER_PRIVATE_KEY = getEnvVar("TESTNET_DEPLOYER_PRIVATE_KEY");
const MAINNET_DEPLOYER_ADDRESS = getEnvVar("MAINNET_DEPLOYER_ADDRESS");
const TESTNET_DEPLOYER_ADDRESS = getEnvVar("TESTNET_DEPLOYER_ADDRESS");

// Watched addresses
const FEED_UPDATER_ADDRESS = getEnvVar("FEED_UPDATER_ADDRESS");
const OPERATOR_ADDRESS = getEnvVar("OPERATOR_ADDRESS");

const TARGET_ADDRESSES: Record<string, string[]> = {
	testnet: [FEED_UPDATER_ADDRESS, OPERATOR_ADDRESS],
	mainnet: [],
};

const TARGET_ALIASES: Record<string, string[]> = {
	testnet: ["Feed Updater EOA", "Operator"],
	mainnet: [],
};

class BalanceChecker {
	private readonly readlineInterface: readline.Interface;
	private readonly mainnetDonorAccount;
	private readonly testnetDonorAccount;

	constructor() {
		this.readlineInterface = readline.createInterface({
			input: process.stdin,
			output: process.stdout,
		});
		this.mainnetDonorAccount = privateKeyToAccount(`0x${MAINNET_DEPLOYER_PRIVATE_KEY}`);
		this.testnetDonorAccount = privateKeyToAccount(`0x${TESTNET_DEPLOYER_PRIVATE_KEY}`);
	}

	async prompt(question: string): Promise<string> {
		return new Promise(resolve => this.readlineInterface.question(question, resolve));
	}

	close(): void {
		this.readlineInterface.close();
	}

	async checkNativeBalance(
		address: string,
		alias: string,
		chain: ConceroNetwork,
	): Promise<BalanceInfo> {
		const { publicClient } = getFallbackClients(chain);
		const balance = await publicClient.getBalance({ address });
		const targetBalance = DEFAULT_TARGET_BALANCE;
		const deficit = balance < targetBalance ? targetBalance - balance : BigInt(0);

		return {
			chain,
			address,
			alias,
			balance,
			donorBalance: BigInt(0),
			targetBalance,
			deficit,
		};
	}

	async topUpWallet(
		wallet: string,
		publicClient: any,
		walletClient: any,
		amount: bigint,
	): Promise<void> {
		try {
			const hash = await walletClient.sendTransaction({ to: wallet, value: amount });
			const receipt = await publicClient.waitForTransactionReceipt({
				...viemReceiptConfig,
				hash,
			});

			log(
				`Topped up ${wallet} with ${formatEther(amount)} ETH. Tx: ${hash} Gas used: ${receipt.cumulativeGasUsed}`,
				"topUpWallet",
				publicClient.chain.name,
			);
		} catch (error) {
			err(
				`Error topping up ${wallet} on ${publicClient.chain.name}: ${error}`,
				"topUpWallet",
			);
		}
	}

	async getBalanceInfo(
		addressesWithAliases: [string, string][],
		chain: ConceroNetwork,
	): Promise<BalanceInfo[]> {
		const balancePromises = addressesWithAliases.map(([address, alias]) =>
			this.checkNativeBalance(address, alias, chain),
		);
		return Promise.all(balancePromises);
	}

	async performTopUps(walletBalances: BalanceInfo[], donorAccount: any): Promise<void> {
		const topUpPromises = walletBalances
			.filter(walletInfo => walletInfo.deficit > BigInt(0))
			.map(async walletInfo => {
				const { publicClient, walletClient } = getFallbackClients(
					walletInfo.chain,
					donorAccount,
				);
				await this.topUpWallet(
					walletInfo.address,
					publicClient,
					walletClient,
					walletInfo.deficit,
				);
			});

		await Promise.all(topUpPromises);
	}

	async ensureNativeBalances(isTestnet: boolean): Promise<void> {
		const networks = isTestnet ? testnetNetworks : mainnetNetworks;
		const donorAccount = isTestnet ? this.testnetDonorAccount : this.mainnetDonorAccount;
		const networkType = isTestnet ? "testnet" : "mainnet";

		const balancesByChain: Record<string, BalanceInfo[]> = {};

		const addresses = TARGET_ADDRESSES[networkType];
		const aliases = TARGET_ALIASES[networkType];

		const walletAddressesWithAliases: [string, string][] = addresses.map((address, index) => [
			address,
			aliases[index],
		]);

		try {
			const networkPromises = Object.values(networks).map(async network => {
				const walletInfos = await this.getBalanceInfo(walletAddressesWithAliases, network);

				const donorInfo = await this.getBalanceInfo(
					[[donorAccount.address, "Donor"]],
					network,
				);

				balancesByChain[network.name] = [...walletInfos, ...donorInfo];
			});

			await Promise.all(networkPromises);

			const displayBalances = this.prepareBalanceDisplay(balancesByChain);

			console.log(`\nWallet and Donor Balances (${networkType}):`);
			console.table(displayBalances);

			const totalDeficit = this.calculateTotalDeficit(displayBalances);
			await this.handleTopUps(totalDeficit, balancesByChain, donorAccount);
		} finally {
			this.close();
		}
	}

	private prepareBalanceDisplay(balancesByChain: Record<string, BalanceInfo[]>): any[] {
		return Object.entries(balancesByChain).flatMap(([chainName, balances]) => {
			const donorBalance = balances.find(b => b.alias === "Donor");
			return balances
				.filter(b => b.alias !== "Donor")
				.map(info => ({
					chain: chainName,
					address: info.alias,
					balance: formatEther(info.balance),
					target: formatEther(info.targetBalance),
					deficit: formatEther(info.deficit),
					donorBalance: formatEther(donorBalance?.balance || BigInt(0)),
				}));
		});
	}

	private calculateTotalDeficit(displayBalances: any[]): bigint {
		return displayBalances.reduce((sum, info) => sum + parseEther(info.deficit), BigInt(0));
	}

	private async handleTopUps(
		totalDeficit: bigint,
		balancesByChain: Record<string, BalanceInfo[]>,
		donorAccount: any,
	): Promise<void> {
		if (totalDeficit > BigInt(0)) {
			const answer = await this.prompt(
				`Do you want to perform top-ups for a total of ${formatEther(totalDeficit)} ETH? (y/n): `,
			);

			if (answer.toLowerCase() === "y") {
				const walletBalances = Object.values(balancesByChain)
					.flat()
					.filter(b => b.alias !== "Donor" && b.deficit > BigInt(0));

				await this.performTopUps(walletBalances, donorAccount);
				console.log("Top-ups completed successfully.");
			} else {
				console.log("Top-ups cancelled by user.");
			}
		} else {
			console.log("No top-ups needed. All balances meet target requirements.");
		}
	}
}

task("ensure-native-balances", "Ensure native token balances across networks")
	.addFlag("testnet", "Use testnet networks instead of mainnet")
	.setAction(async taskArgs => {
		const balanceChecker = new BalanceChecker();
		await balanceChecker.ensureNativeBalances(taskArgs.testnet);
	});

export default async function ensureNativeBalances(isTestnet: boolean): Promise<void> {
	const balanceChecker = new BalanceChecker();
	await balanceChecker.ensureNativeBalances(isTestnet);
}
