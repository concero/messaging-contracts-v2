import {
	PrivateKeyAccount,
	PublicClient,
	WalletClient,
	createPublicClient,
	createWalletClient,
	fallback,
	formatEther,
	http,
	parseEther,
} from "viem";

import { conceroNetworks } from "../../constants";
import { urls } from "../../constants/rpcUrls";
import { ConceroNetwork } from "../../types/ConceroNetwork";

interface NetworkConfig {
	name: string;
	network: ConceroNetwork;
}

interface ClientPair {
	publicClient: PublicClient;
	walletClient: WalletClient;
}

interface NativeTokenSenderConfig {
	timeout: number;
	retryCount: number;
	retryDelay: number;
}

export class NativeTokenSender {
	private static instance: NativeTokenSender;
	private transactionGasLimit: bigint;
	private senderAccount: PrivateKeyAccount;
	private config: NativeTokenSenderConfig;
	private isTestnet: boolean;

	constructor(
		senderAccount: PrivateKeyAccount,
		transactionGasLimit: bigint,
		isTestnet?: boolean,
		config?: NativeTokenSenderConfig,
	) {
		this.senderAccount = senderAccount;
		this.transactionGasLimit = transactionGasLimit;
		this.isTestnet = isTestnet ?? false;
		this.config = config ?? {
			retryCount: 5,
		};
	}

	public static createInstance(
		senderAccount: PrivateKeyAccount,
		transactionGasLimit: bigint,
		isTestnet?: boolean,
	): NativeTokenSender {
		NativeTokenSender.instance = new NativeTokenSender(
			senderAccount,
			transactionGasLimit,
			isTestnet,
		);
		return NativeTokenSender.instance;
	}

	async sendByTransactionCount(
		recipient: string,
		txCount: number,
		chainNames: string[],
	): Promise<void> {
		const networks = this.getFilteredNetworks(chainNames);

		for (const network of networks) {
			const { publicClient, walletClient } = this.createClients(network.network);

			const gasPrice = await this.getActualGasPrice(publicClient);
			const amount = this.transactionGasLimit * gasPrice * BigInt(txCount);

			if (amount === 0n) {
				console.log(`No amount to send on ${network.name}`);
				continue;
			}

			await this.sendValue(recipient, amount, publicClient, walletClient);
		}
	}

	async sendByAmount(recipient: string, amount: string, chainNames: string[]): Promise<void> {
		const networks = this.getFilteredNetworks(chainNames);
		const amountInWei = parseEther(amount);

		if (amountInWei === 0n) {
			throw new Error(`Amount should be greater than 0`);
		}

		for (const network of networks) {
			const { publicClient, walletClient } = this.createClients(network.network);
			await this.sendValue(recipient, amountInWei, publicClient, walletClient);
		}
	}

	private getFilteredNetworks(chainNames: string[]): NetworkConfig[] {
		return Object.entries(conceroNetworks)
			.filter(([_, network]) =>
				this.isTestnet ? network.type === "testnet" : network.type === "mainnet",
			)
			.filter(([name, _]) => !chainNames || chainNames.includes(name))
			.map(([name, network]) => ({ name, network: network as ConceroNetwork }));
	}

	private async getActualGasPrice(publicClient: PublicClient): Promise<bigint> {
		const block = await publicClient.getBlock();

		const isEIP1559 = !!block.baseFeePerGas;

		let gasPrice = 0n;
		if (isEIP1559) {
			const { maxFeePerGas, maxPriorityFeePerGas } = await publicClient.estimateFeesPerGas();
			gasPrice = maxFeePerGas + maxPriorityFeePerGas;
		} else {
			gasPrice = await publicClient.getGasPrice();
		}

		return gasPrice;
	}

	private createClients(network: ConceroNetwork): ClientPair {
		const transport = this.createTransport(network);

		const publicClient = createPublicClient({
			transport,
			chain: network.viemChain,
		});

		const walletClient = createWalletClient({
			transport,
			chain: network.viemChain,
			account: this.senderAccount,
		});

		return { publicClient, walletClient };
	}

	private createTransport(chain: ConceroNetwork) {
		const rpcUrls = urls[chain.name] || [];

		if (!rpcUrls || rpcUrls.length === 0) {
			throw new Error(`No RPC URLs available for chain ${chain.name}`);
		}

		return fallback(
			rpcUrls.map(url => http(url)),
			{ retryCount: this.config.retryCount },
		);
	}

	private async sendValue(
		recipient: string,
		amount: bigint,
		publicClient: PublicClient,
		walletClient: WalletClient,
	): Promise<void> {
		try {
			const actualBalance = await publicClient.getBalance({
				address: this.senderAccount.address,
			});

			console.log(`Balance on ${publicClient.chain?.name}: ${formatEther(actualBalance)}`);

			if (actualBalance < amount) {
				throw new Error(
					`Insufficient balance for ${publicClient.chain?.name}. Required: ${formatEther(amount)}, Available: ${formatEther(actualBalance)}`,
				);
			}

			const txHash = await walletClient.sendTransaction({
				account: this.senderAccount,
				value: amount,
				to: recipient as `0x${string}`,
				chain: publicClient.chain,
				gas: 100_000n,
			});

			const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

			if (receipt.status === "success") {
				console.log(
					`Transaction successful on ${publicClient.chain?.name}: amount: ${formatEther(amount)}, txHash: ${txHash}`,
				);
			} else {
				console.log(
					`Transaction failed on ${publicClient.chain?.name}: amount: ${formatEther(amount)}, txHash: ${txHash}`,
				);
			}
		} catch (error) {
			console.error(
				`Error sending transaction on ${publicClient.chain?.name}:`,
				error.message,
			);
			throw error;
		}
	}

	public dispose(): void {
		this.senderAccount = null as any;
		this.transactionGasLimit = 0n;
		this.isTestnet = false;
		this.config = {
			timeout: 10000,
			retryCount: 1,
			retryDelay: 250,
		};
	}
}
