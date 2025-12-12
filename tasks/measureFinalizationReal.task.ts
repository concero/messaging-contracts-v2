import { type PublicClient, createPublicClient, http } from "viem";

import { task } from "hardhat/config";
import type { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { getFallbackClients } from "../utils";
import { log } from "../utils/log";

interface MeasureResult {
	networkName: string;
	chainId: number;
	blocksToFinalize: number;
	secondsToFinalize: number;
	error?: string;
}

interface AggregatedResult {
	networkName: string;
	chainId: number;
	avgBlocks: number;
	minBlocks: number;
	maxBlocks: number;
	avgSeconds: number;
	minSeconds: number;
	maxSeconds: number;
	samples: number;
	error?: string;
}

function formatTime(seconds: number): string {
	if (seconds < 60) {
		return `${Math.round(seconds)}s`;
	}
	const minutes = Math.floor(seconds / 60);
	const remainingSeconds = Math.round(seconds % 60);
	return `${minutes}m ${remainingSeconds}s`;
}

async function singleMeasure(
	publicClient: PublicClient,
): Promise<{ blocks: number; seconds: number }> {
	const [latestBlock, finalizedBlock] = await Promise.all([
		publicClient.getBlock({ blockTag: "latest" }),
		publicClient.getBlock({ blockTag: "finalized" }),
	]);

	return {
		blocks: Number(latestBlock.number - finalizedBlock.number),
		seconds: Number(latestBlock.timestamp - finalizedBlock.timestamp),
	};
}

async function measureWithRpcUrl(
	rpcUrl: string,
	iterations: number,
	delay: number,
): Promise<AggregatedResult> {
	try {
		const publicClient = createPublicClient({
			transport: http(rpcUrl),
		});

		const chainId = Number(await publicClient.getChainId());
		const samples: { blocks: number; seconds: number }[] = [];

		for (let i = 0; i < iterations; i++) {
			const result = await singleMeasure(publicClient as PublicClient);
			samples.push(result);

			if (iterations > 1) {
				log(
					`  Sample ${i + 1}/${iterations}: ${result.blocks} blocks (${formatTime(result.seconds)})`,
					"measureFinalization",
				);
			}

			if (i < iterations - 1) {
				await new Promise(resolve => setTimeout(resolve, delay));
			}
		}

		const blocks = samples.map(s => s.blocks);
		const seconds = samples.map(s => s.seconds);

		return {
			networkName: rpcUrl,
			chainId,
			avgBlocks: Math.round(blocks.reduce((a, b) => a + b, 0) / blocks.length),
			minBlocks: Math.min(...blocks),
			maxBlocks: Math.max(...blocks),
			avgSeconds: seconds.reduce((a, b) => a + b, 0) / seconds.length,
			minSeconds: Math.min(...seconds),
			maxSeconds: Math.max(...seconds),
			samples: iterations,
		};
	} catch (error: any) {
		return {
			networkName: rpcUrl,
			chainId: 0,
			avgBlocks: 0,
			minBlocks: 0,
			maxBlocks: 0,
			avgSeconds: 0,
			minSeconds: 0,
			maxSeconds: 0,
			samples: 0,
			error: error.message,
		};
	}
}

async function measureNetworkFinalization(
	networkName: string,
	iterations: number,
	delay: number,
): Promise<AggregatedResult> {
	try {
		const network = conceroNetworks[networkName as keyof typeof conceroNetworks];
		if (!network) {
			throw new Error(`Network ${networkName} not found`);
		}

		const { publicClient } = getFallbackClients(network as any);
		const samples: { blocks: number; seconds: number }[] = [];

		log(`${networkName}: Measuring...`, "measureFinalization");

		for (let i = 0; i < iterations; i++) {
			const result = await singleMeasure(publicClient as PublicClient);
			samples.push(result);

			if (iterations > 1) {
				log(
					`  Sample ${i + 1}/${iterations}: ${result.blocks} blocks (${formatTime(result.seconds)})`,
					"measureFinalization",
				);
			}

			if (i < iterations - 1) {
				await new Promise(resolve => setTimeout(resolve, delay));
			}
		}

		const blocks = samples.map(s => s.blocks);
		const seconds = samples.map(s => s.seconds);

		return {
			networkName,
			chainId: network.chainId,
			avgBlocks: Math.round(blocks.reduce((a, b) => a + b, 0) / blocks.length),
			minBlocks: Math.min(...blocks),
			maxBlocks: Math.max(...blocks),
			avgSeconds: seconds.reduce((a, b) => a + b, 0) / seconds.length,
			minSeconds: Math.min(...seconds),
			maxSeconds: Math.max(...seconds),
			samples: iterations,
		};
	} catch (error: any) {
		return {
			networkName,
			chainId: 0,
			avgBlocks: 0,
			minBlocks: 0,
			maxBlocks: 0,
			avgSeconds: 0,
			minSeconds: 0,
			maxSeconds: 0,
			samples: 0,
			error: error.message,
		};
	}
}

function formatResult(result: AggregatedResult): string {
	if (result.samples === 1) {
		return `${result.avgBlocks} blocks (${formatTime(result.avgSeconds)})`;
	}
	return `avg: ${result.avgBlocks} blocks (${formatTime(result.avgSeconds)}) | min: ${result.minBlocks} (${formatTime(result.minSeconds)}) | max: ${result.maxBlocks} (${formatTime(result.maxSeconds)})`;
}

task("measure-finalization-real", "Measure blocks lag between latest and finalized")
	.addOptionalParam("networks", "Comma-separated list of networks to test", "")
	.addOptionalParam("rpcUrl", "Direct RPC URL to use (ignores networks param)", "")
	.addOptionalParam("iterations", "Number of samples to take", "1")
	.addOptionalParam("delay", "Delay between samples in ms", "1000")
	.setAction(async (taskArgs: any, hre: HardhatRuntimeEnvironment) => {
		const iterations = parseInt(taskArgs.iterations, 10);
		const delay = parseInt(taskArgs.delay, 10);

		if (iterations > 1) {
			log(
				`Taking ${iterations} samples with ${delay}ms delay between each`,
				"measureFinalization",
			);
		}

		// If rpcUrl provided, use it directly
		if (taskArgs.rpcUrl) {
			log(`Using direct RPC URL: ${taskArgs.rpcUrl}`, "measureFinalization");
			const result = await measureWithRpcUrl(taskArgs.rpcUrl, iterations, delay);

			log(`\n=== RESULTS ===`, "measureFinalization");
			if (result.error) {
				log(`❌ Chain ${result.chainId}: ${result.error}`, "measureFinalization");
			} else {
				log(`✅ Chain ${result.chainId}: ${formatResult(result)}`, "measureFinalization");
			}
			return;
		}

		const networksToTest = taskArgs.networks
			? taskArgs.networks.split(",").map((name: string) => name.trim())
			: ["arbitrumSepolia"];

		log(
			`Testing finalization on networks: ${networksToTest.join(", ")}`,
			"measureFinalization",
		);

		// Run sequentially to avoid rate limits and for cleaner output
		const results: AggregatedResult[] = [];
		for (const networkName of networksToTest) {
			const result = await measureNetworkFinalization(networkName, iterations, delay);
			results.push(result);
		}

		log(`\n=== RESULTS ===`, "measureFinalization");
		for (const result of results) {
			if (result.error) {
				log(`❌ ${result.networkName}: ${result.error}`, "measureFinalization");
			} else {
				log(`✅ ${result.networkName}: ${formatResult(result)}`, "measureFinalization");
			}
		}
	});

export default "measure-finalization-real";
