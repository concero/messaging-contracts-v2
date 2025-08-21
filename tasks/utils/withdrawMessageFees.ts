import * as readline from "readline";

import { formatEther, zeroAddress } from "viem";

import { ProxyEnum, conceroNetworks, getViemReceiptConfig } from "../../constants";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { err, getEnvAddress, getFallbackClients, log } from "../../utils";

interface ConceroFeeInfo {
	chainName: string;
	contractAlias: string;
	contractAddress: string;
	availableFees: bigint;
	formattedFees: string;
}

const MIN_WITHDRAWAL_AMOUNT = 0.1; // 0.1 ETH

async function checkAvailableConceroFees(
	isTestnet: boolean,
	chainNames?: string[],
	needShowErrors?: boolean,
): Promise<ConceroFeeInfo[]> {
	const { abi } = await import(
		"../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);
	const results: ConceroFeeInfo[] = [];

	// Process networks based on testnet flag and optional chain filter
	const networksToCheck = Object.entries(conceroNetworks)
		.filter(([_, network]) =>
			isTestnet ? network.type === "testnet" : network.type === "mainnet",
		)
		.filter(([name, _]) => !chainNames || chainNames.includes(name))
		.map(([name, network]) => ({ name, network: network as ConceroNetwork }));

	for (const { name, network } of networksToCheck) {
		try {
			const [contractAddress, contractAlias] = getEnvAddress(ProxyEnum.routerProxy, name);
			const { publicClient } = getFallbackClients(network);

			const availableFees = (await publicClient.readContract({
				address: contractAddress,
				abi,
				functionName: "getWithdrawableConceroFee",
			})) as bigint;

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
			const errorMessage = error instanceof Error ? error.message : String(error);
			if (needShowErrors) {
				err(`Error checking fees on ${name}: ${errorMessage}`, "checkAvailableConceroFees");
			} else {
				err(`Error checking fees on ${name}`, "checkAvailableConceroFees");
			}
		}
	}

	return results;
}

async function askMinimumAmount(): Promise<number> {
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

	const wantMin = await ask("Do you want to set a minimum withdrawal amount? (y/n): ");
	if (wantMin.toLowerCase() !== "y") {
		rl.close();
		return 0; // No minimum
	}

	let minAmount = 0;
	while (true) {
		const minInput = await ask(
			`Enter minimum withdrawal amount in ETH (default ${MIN_WITHDRAWAL_AMOUNT}): `,
		);
		if (minInput === "") {
			break;
		}

		const parsed = parseFloat(minInput);
		if (isNaN(parsed) || parsed < 0) {
			console.log("Please enter a valid positive number");
			continue;
		}

		minAmount = parsed;
		break;
	}

	rl.close();
	return minAmount;
}

async function promptToWithdraw(): Promise<Boolean> {
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

	const withdrawAll = await ask(`Do you want to withdraw fees from selected chains? (y/n): `);
	if (withdrawAll.toLowerCase() === "y") {
		rl.close();
		return true;
	}

	rl.close();
	return false;
}

export async function withdrawMessageFees(
	chains: string,
	isTestnet?: boolean,
	needShowErrors?: boolean,
): Promise<void> {
	let chainNames: string[] | undefined;

	// Parse chains parameter if provided
	if (chains && chains.trim() !== "") {
		chainNames = chains
			.split(",")
			.map(chain => chain.trim())
			.filter(Boolean);
		log(`Checking fees for specific chains: ${chainNames.join(", ")}`, "withdrawMessageFees");
	} else {
		log(
			`Checking fees for all ${isTestnet ? "testnet" : "mainnet"} chains`,
			"withdrawMessageFees",
		);
	}

	const availableFees = await checkAvailableConceroFees(
		isTestnet ?? false,
		chainNames,
		needShowErrors,
	);

	if (availableFees.length === 0) {
		log("No withdrawable fees found on any chains", "withdrawMessageFees");
		return;
	}

	// Display available fees
	log("Available fees found:", "withdrawMessageFees");
	const displayFees = availableFees.map(fee => ({
		Chain: fee.chainName,
		Contract: fee.contractAlias,
		"Available Fees (ETH)": fee.formattedFees,
	}));
	console.table(displayFees);

	// Ask for minimum amount interactively
	const minAmountValue = await askMinimumAmount();

	// Filter by minimum amount
	const filteredFees = availableFees.filter(fee => {
		const feeAmount = parseFloat(fee.formattedFees);
		return feeAmount >= minAmountValue;
	});

	if (filteredFees.length === 0) {
		log(`No fees above minimum amount of ${minAmountValue} ETH`, "withdrawMessageFees");
		return;
	}

	if (filteredFees.length < availableFees.length) {
		log(
			`Filtered to ${filteredFees.length} chains with fees >= ${minAmountValue} ETH`,
			"withdrawMessageFees",
		);
	}

	const needToWithdrawAll = await promptToWithdraw();
	if (!needToWithdrawAll) {
		log("Withdrawal cancelled.", "withdrawMessageFees");
		return;
	}

	const { abi } = await import(
		"../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	for (const fee of filteredFees) {
		const chain = conceroNetworks[fee.chainName as keyof typeof conceroNetworks];
		const { publicClient, walletClient, account } = getFallbackClients(chain);

		log(`Withdrawing ${fee.formattedFees} ETH from ${fee.chainName}...`, "withdrawMessageFees");

		try {
			const txHash = await walletClient.writeContract({
				address: fee.contractAddress as `0x${string}`,
				abi: abi,
				functionName: "withdrawConceroFees",
				account,
				args: [[zeroAddress], [fee.availableFees]],
				chain: chain.viemChain,
			});

			await publicClient.waitForTransactionReceipt({
				...getViemReceiptConfig(chain as ConceroNetwork),
				hash: txHash,
			});

			log(
				`Successfully withdrawn ${fee.formattedFees} ETH from ${fee.chainName}`,
				"withdrawMessageFees",
				chain.name,
			);
		} catch (error) {
			if (needShowErrors) {
				const errorMessage = error instanceof Error ? error.message : String(error);
				err(
					`Error withdrawing ${fee.formattedFees} ETH from ${fee.chainName}: ${errorMessage}`,
					"withdrawMessageFees",
				);
			} else {
				err(
					`Error withdrawing ${fee.formattedFees} ETH from ${fee.chainName}`,
					"withdrawMessageFees",
				);
			}
		}
	}
}
