import type { Address } from "viem";

import { task } from "hardhat/config";
import type { HardhatRuntimeEnvironment } from "hardhat/types";

import { getNetworkEnvKey } from "@concero/contract-utils";

import { conceroNetworks } from "../constants";
import { getFallbackClients } from "../utils";
import { getEnvVar } from "../utils/getEnvVar";
import { log } from "../utils/log";

async function measureNetworkFinalization(networkName: string): Promise<{
	networkName: string;
	chainId: number;
	blocksToFinalize: number;
	error?: string;
}> {
	try {
		const network = conceroNetworks[networkName];
		if (!network) {
			throw new Error(`Network ${networkName} not found`);
		}

		// Get router address from env
		const routerAddress = getEnvVar(
			`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(networkName)}` as any,
		);
		if (!routerAddress) {
			throw new Error(`Router address not found for ${networkName}`);
		}

		const { walletClient, publicClient } = getFallbackClients(network as any);

		// Capture latest block before sending transaction
		const latestBeforeTx = await publicClient.getBlockNumber();

		log(
			`${networkName}: Sending transaction to router ${routerAddress}`,
			"measureFinalization",
		);

		// Send foo() transaction with minimal gas
		const txHash = await walletClient.sendTransaction({
			to: routerAddress as Address,
			data: "0x",
			gas: 30000n,
		});

		log(`${networkName}: Transaction sent: ${txHash}`, "measureFinalization");

		// Get transaction block number
		const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
		const txBlockNumber = receipt.blockNumber;

		log(`${networkName}: Transaction mined in block: ${txBlockNumber}`, "measureFinalization");

		// Wait until our specific block becomes finalized
		let attempts = 0;
		const maxAttempts = 1000;

		while (attempts < maxAttempts) {
			try {
				// Try to get our specific block with finalized tag
				const finalizedBlock = await publicClient.getBlock({
					blockNumber: txBlockNumber,
					blockTag: "finalized" as any,
				});

				if (finalizedBlock && finalizedBlock.number === txBlockNumber) {
					// Our block is now finalized! Calculate how many blocks passed since sending
					const latestAfterFinalization = await publicClient.getBlockNumber();
					const blocksToFinalize = Number(latestAfterFinalization - latestBeforeTx);

					log(
						`${networkName}: ✅ Block ${txBlockNumber} is finalized! Latest before: ${latestBeforeTx}, Latest after: ${latestAfterFinalization}, Lag: ${blocksToFinalize} blocks`,
						"measureFinalization",
					);

					return {
						networkName,
						chainId: network.chainId,
						blocksToFinalize,
					};
				}
			} catch (error: any) {
				// Our block is not finalized yet, continue waiting
			}

			attempts++;
			await new Promise(resolve => setTimeout(resolve, 200));
		}

		throw new Error(
			`Timeout waiting for block ${txBlockNumber} finalization after ${maxAttempts} attempts`,
		);
	} catch (error: any) {
		return {
			networkName,
			chainId: 0,
			blocksToFinalize: 0,
			error: error.message,
		};
	}
}

task("measure-finalization-real", "Send foo() transaction and measure blocks to finalization")
	.addOptionalParam("networks", "Comma-separated list of networks to test", "")
	.setAction(async (taskArgs: any, hre: HardhatRuntimeEnvironment) => {
		const networksToTest = taskArgs.networks
			? taskArgs.networks.split(",").map((name: string) => name.trim())
			: ["arbitrumSepolia"];

		log(
			`Testing finalization on networks: ${networksToTest.join(", ")}`,
			"measureFinalization",
		);

		// Run measurements async for all networks
		const promises = networksToTest.map((networkName: string) =>
			measureNetworkFinalization(networkName),
		);

		const results = await Promise.all(promises);

		// Output results
		log(`\n=== RESULTS ===`, "measureFinalization");
		for (const result of results) {
			if (result.error) {
				log(`❌ ${result.networkName}: ${result.error}`, "measureFinalization");
			} else {
				log(
					`✅ ${result.networkName}: ${result.blocksToFinalize} blocks to finalize`,
					"measureFinalization",
				);
			}
		}
	});

export default "measure-finalization-real";
