import * as readline from "readline";

import { formatEther, zeroAddress } from "viem";

import { task } from "hardhat/config";

import { ProxyEnum, conceroNetworks, viemReceiptConfig } from "../constants";
import { getEnvAddress, getFallbackClients, log } from "../utils";

interface ConceroFeeInfo {
	chainName: string;
	contractAlias: string;
	contractAddress: string;
	availableFees: bigint;
	formattedFees: string;
}

async function checkAvailableConceroFees(isTestnet: boolean): Promise<ConceroFeeInfo[]> {
	const { abi } = await import(
		"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);
	const results: ConceroFeeInfo[] = [];

	// Process networks based on testnet flag
	const networksToCheck = Object.entries(conceroNetworks)
		.filter(([_, network]) =>
			isTestnet ? network.type === "testnet" : network.type === "mainnet",
		)
		.map(([name, network]) => ({ name, network }));

	for (const { name, network } of networksToCheck) {
		try {
			const [contractAddress, contractAlias] = getEnvAddress(ProxyEnum.routerProxy, name);
			const { publicClient } = getFallbackClients(network);

			const availableFees = await publicClient.readContract({
				address: contractAddress,
				abi,
				functionName: "getWithdrawableConceroFee",
				chain: network.viemChain,
			});

			if (availableFees > BigInt(0)) {
				results.push({
					chainName: name,
					contractAlias,
					contractAddress,
					availableFees,
					formattedFees: formatEther(availableFees),
				});
			}
		} catch (error) {
			console.error(`Error checking fees on ${name}:`, error);
		}
	}

	return results;
}

async function withdrawFees(isTestnet: boolean) {
	const availableFees = await checkAvailableConceroFees(isTestnet);

	if (availableFees.length === 0) {
		console.log("No fees available for withdrawal on any chain.");
		return;
	}

	console.log("\nAvailable Concero Fees for withdrawal:");
	const displayFees = availableFees.map(fee => ({
		Chain: fee.chainName,
		Contract: fee.contractAlias,
		"Available Fees (ETH)": fee.formattedFees,
	}));
	console.table(displayFees);

	const feesToWithdraw = await promptChainsToWithdraw(availableFees);
	if (feesToWithdraw.length === 0) {
		console.log("No fees selected for withdrawal.");
		return;
	}

	const { abi } = await import(
		"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	for (const fee of feesToWithdraw) {
		const chain = conceroNetworks[fee.chainName];
		const { publicClient, walletClient, account } = getFallbackClients(chain);

		console.log(`\nWithdrawing ${fee.formattedFees} ETH from ${fee.chainName}...`);

		try {
			const { request } = await publicClient.simulateContract({
				address: fee.contractAddress,
				abi,
				functionName: "withdrawConceroFees",
				account,
				args: [[zeroAddress], [fee.availableFees]],
				chain: chain.viemChain,
			});

			const hash = await walletClient.writeContract(request);
			const { cumulativeGasUsed } = await publicClient.waitForTransactionReceipt({
				...viemReceiptConfig,
				hash,
			});

			log(
				`Successfully withdrawn ${fee.formattedFees} ETH from ${fee.chainName} (Gas Used: ${cumulativeGasUsed})`,
				"withdrawFees",
				chain.name,
			);
		} catch (error) {
			console.error(`Error withdrawing fees from ${fee.chainName}:`, error);
		}
	}
}

async function promptChainsToWithdraw(availableFees: ConceroFeeInfo[]): Promise<ConceroFeeInfo[]> {
	const rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout,
	});

	const ask = (question: string): Promise<string> => {
		return new Promise(resolve => {
			rl.question(question, answer => {
				resolve(answer.trim());
			});
		});
	};

	// Prompt for withdrawal of all fees
	const withdrawAll = await ask("Do you want to withdraw fees from all chains? (y/n): ");
	if (withdrawAll.toLowerCase() === "y") {
		rl.close();
		return availableFees;
	}

	// Prompt for individual chains
	const selected: ConceroFeeInfo[] = [];
	for (const fee of availableFees) {
		const answer = await ask(
			`Withdraw ${fee.formattedFees} ETH from ${fee.chainName}? (y/n): `,
		);
		if (answer.toLowerCase() === "y") {
			selected.push(fee);
		}
	}

	rl.close();
	return selected;
}

task("withdraw-fees", "Withdraw native token fees accumulated in Concero contracts")
	.addFlag("testnet", "Use testnet instead of mainnet")
	.setAction(async taskArgs => {
		await withdrawFees(taskArgs.testnet);
	});

export default {};
