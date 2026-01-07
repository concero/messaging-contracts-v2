/**
 * @file measureFinalizationReal.task.ts
 * @description Hardhat task for measuring blockchain finalization times and checking
 * finality tag support across multiple networks. Used to determine optimal block
 * confirmations for event log retrieval.
 */
import { task } from "hardhat/config";

import * as fs from "fs";
import * as path from "path";

import type { HardhatRuntimeEnvironment } from "hardhat/types";
import { type PublicClient, createPublicClient, http } from "viem";

import { conceroNetworks, mainnetNetworks, testnetNetworks } from "../constants";
import type { ConceroNetwork } from "../types/ConceroNetwork";
import { getFallbackClients } from "../utils";
import { log } from "../utils/log";

// ============================================================================
// Types
// ============================================================================

/** Result of finality check and measurement for a single network */
interface FinalityCheckResult {
	chainId: number;
	finalityTagEnabled: boolean;
	minBlockConfirmations: number | null;
	avgSeconds?: number;
	avgBlocks?: number;
	error?: string;
}

/** Output JSON format: network name -> finality check result */
type OutputJson = Record<string, FinalityCheckResult>;

/** Task arguments for measure-finalization */
interface MeasureFinalizationArgs {
	networks?: string;
	rpcurl?: string;
	env?: "testnet" | "mainnet";
	output?: string;
	iterations: string;
	delay: string;
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Formats seconds into human-readable time string
 * @param seconds - Time in seconds
 * @returns Formatted string like "45s" or "2m 30s"
 */
function formatTime(seconds: number): string {
	if (seconds < 60) {
		return `${Math.round(seconds)}s`;
	}
	const minutes = Math.floor(seconds / 60);
	const remainingSeconds = Math.round(seconds % 60);
	return `${minutes}m ${remainingSeconds}s`;
}

/**
 * Checks if RPC endpoint supports "finalized" block tag
 * @param publicClient - Viem public client
 * @returns true if finalized tag is supported, false otherwise
 */
async function checkFinalityTagSupport(publicClient: PublicClient): Promise<boolean> {
	try {
		await publicClient.getBlock({ blockTag: "finalized" });
		return true;
	} catch {
		return false;
	}
}

/**
 * Determines minimum block confirmations based on average finalization time.
 * Thresholds:
 * - < 30s: 1 confirmation (fast chains like L2s)
 * - < 1800s: 3 confirmations (medium speed chains)
 * - >= 1800s: 5 confirmations (slower chains)
 *
 * @param avgSeconds - Average finalization time in seconds
 * @returns Recommended minimum block confirmations (1, 3, or 5)
 */
function getMinBlockConfirmations(avgSeconds: number): number {
	if (avgSeconds < 30) return 1;
	if (avgSeconds < 1800) return 3;
	return 5;
}

/**
 * Performs a single measurement of block lag between latest and finalized blocks
 * @param publicClient - Viem public client
 * @returns Object with blocks and seconds difference
 */
async function singleMeasure(
	publicClient: PublicClient,
): Promise<{ blocks: number; seconds: number }> {
	const [latestBlock, finalizedBlock] = await Promise.all([
		publicClient.getBlock({ blockTag: "latest" }),
		publicClient.getBlock({ blockTag: "finalized" }),
	]);

	// Use Math.max to handle edge cases where finalized might be slightly ahead due to async
	return {
		blocks: Math.max(0, Number(latestBlock.number - finalizedBlock.number)),
		seconds: Math.max(0, Number(latestBlock.timestamp - finalizedBlock.timestamp)),
	};
}

/**
 * Universal function to check finality support and measure finalization time.
 * First checks if "finalized" tag is supported, then takes multiple samples.
 *
 * @param publicClient - Viem public client
 * @param networkName - Network identifier for logging
 * @param chainId - Chain ID
 * @param iterations - Number of measurement samples
 * @param delay - Delay between samples in ms
 * @returns Finality check result
 */
async function measureFinality(
	publicClient: PublicClient,
	networkName: string,
	chainId: number,
	iterations: number,
	delay: number,
): Promise<FinalityCheckResult> {
	log(`\n[${networkName}] Checking finality support...`, "measureFinalization");

	try {
		// Check if finality tag is supported
		const finalitySupported = await checkFinalityTagSupport(publicClient);

		if (!finalitySupported) {
			log(`  ❌ Finality tag NOT supported`, "measureFinalization");
			return {
				chainId,
				finalityTagEnabled: false,
				minBlockConfirmations: null,
			};
		}

		log(`  ✅ Finality tag supported, measuring...`, "measureFinalization");

		// Take multiple samples
		const samples: { blocks: number; seconds: number }[] = [];
		for (let i = 0; i < iterations; i++) {
			const result = await singleMeasure(publicClient);
			samples.push(result);

			log(
				`    Sample ${i + 1}/${iterations}: ${result.blocks} blocks (${formatTime(result.seconds)})`,
				"measureFinalization",
			);

			if (i < iterations - 1) {
				await new Promise(resolve => setTimeout(resolve, delay));
			}
		}

		// Calculate averages
		const avgSeconds = samples.reduce((a, b) => a + b.seconds, 0) / samples.length;
		const avgBlocks = Math.round(samples.reduce((a, b) => a + b.blocks, 0) / samples.length);
		const minBlockConfirmations = getMinBlockConfirmations(avgSeconds);

		log(
			`  Result: avg ${avgBlocks} blocks (${formatTime(avgSeconds)}) → minBlockConfirmations: ${minBlockConfirmations}`,
			"measureFinalization",
		);

		return {
			chainId,
			finalityTagEnabled: true,
			minBlockConfirmations,
			avgSeconds,
			avgBlocks,
		};
	} catch (error: any) {
		log(`  ❌ Error: ${error.message}`, "measureFinalization");
		return {
			chainId,
			finalityTagEnabled: false,
			minBlockConfirmations: null,
			error: error.message,
		};
	}
}

// ============================================================================
// Task Action Handler
// ============================================================================

/**
 * Handler for measure-finalization task.
 * Checks finality tag support and measures finalization times.
 *
 * Modes:
 * 1. --env testnet|mainnet: Check ALL networks in the environment, write to JSON
 * 2. --rpcurl: Check a single RPC endpoint directly
 * 3. --networks: Check specific networks by name
 */
async function handleMeasureFinalization(
	taskArgs: MeasureFinalizationArgs,
	hre: HardhatRuntimeEnvironment,
): Promise<void> {
	const iterations = parseInt(taskArgs.iterations, 10);
	const delay = parseInt(taskArgs.delay, 10);

	log(`Taking ${iterations} samples with ${delay}ms delay between each`, "measureFinalization");

	const results: OutputJson = {};

	// Mode 1: Check all networks in environment and write to JSON
	if (taskArgs.env) {
		const env = taskArgs.env;
		if (env !== "testnet" && env !== "mainnet") {
			throw new Error("--env must be 'testnet' or 'mainnet'");
		}

		// Determine output path: --output can be a directory or full file path
		const defaultFileName = `finality-${env}.json`;
		let outputPath: string;
		if (taskArgs.output) {
			// If output ends with / or is an existing directory, append default filename
			if (taskArgs.output.endsWith("/") || taskArgs.output.endsWith(path.sep)) {
				outputPath = path.join(taskArgs.output, defaultFileName);
			} else {
				outputPath = taskArgs.output;
			}
		} else {
			outputPath = path.join(process.cwd(), defaultFileName);
		}

		const networks = env === "testnet" ? testnetNetworks : mainnetNetworks;
		const networkNames = Object.keys(networks);

		// Ensure output directory exists
		const outputDir = path.dirname(outputPath);
		if (!fs.existsSync(outputDir)) {
			fs.mkdirSync(outputDir, { recursive: true });
		}

		log(`\nChecking ${networkNames.length} ${env} networks...`, "measureFinalization");

		for (const networkName of networkNames) {
			try {
				const network = networks[networkName as keyof typeof networks] as ConceroNetwork;
				const { publicClient } = getFallbackClients(network);
				results[networkName] = await measureFinality(
					publicClient as PublicClient,
					networkName,
					network.chainId,
					iterations,
					delay,
				);
			} catch (error: any) {
				log(`\n[${networkName}] ❌ Error: ${error.message}`, "measureFinalization");
				results[networkName] = {
					chainId: 0,
					finalityTagEnabled: false,
					minBlockConfirmations: null,
					error: error.message,
				};
			}

			// Write incrementally after each network to avoid data loss
			fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));
		}

		log(`\n=== COMPLETE ===`, "measureFinalization");
		log(`Results written to: ${outputPath}`, "measureFinalization");

		// Summary
		const supported = Object.values(results).filter(r => r.finalityTagEnabled).length;
		const total = Object.keys(results).length;
		log(`Finality supported: ${supported}/${total} networks`, "measureFinalization");
		return;
	}

	// Mode 2: Direct RPC URL
	if (taskArgs.rpcurl) {
		log(`\nUsing direct RPC URL: ${taskArgs.rpcurl}`, "measureFinalization");

		const publicClient = createPublicClient({
			transport: http(taskArgs.rpcurl),
		});
		const chainId = Number(await publicClient.getChainId());

		const result = await measureFinality(
			publicClient as PublicClient,
			`rpc:${chainId}`,
			chainId,
			iterations,
			delay,
		);

		log(`\n=== RESULT ===`, "measureFinalization");
		if (result.finalityTagEnabled) {
			log(
				`✅ Chain ${chainId}: finality supported, minBlockConfirmations: ${result.minBlockConfirmations}`,
				"measureFinalization",
			);
		} else {
			log(
				`❌ Chain ${chainId}: ${result.error || "finality tag not supported"}`,
				"measureFinalization",
			);
		}
		return;
	}

	// Mode 3: Named networks
	const networksToTest = taskArgs.networks
		? taskArgs.networks.split(",").map((name: string) => name.trim())
		: [];

	if (networksToTest.length === 0) {
		throw new Error("Provide --env, --rpcurl, or --networks parameter");
	}

	log(`\nTesting networks: ${networksToTest.join(", ")}`, "measureFinalization");

	for (const networkName of networksToTest) {
		try {
			const network = conceroNetworks[networkName as keyof typeof conceroNetworks];
			if (!network) {
				throw new Error("Network not found in config");
			}

			const { publicClient } = getFallbackClients(network as ConceroNetwork);
			results[networkName] = await measureFinality(
				publicClient as PublicClient,
				networkName,
				network.chainId,
				iterations,
				delay,
			);
		} catch (error: any) {
			log(`\n[${networkName}] ❌ Error: ${error.message}`, "measureFinalization");
			results[networkName] = {
				chainId: 0,
				finalityTagEnabled: false,
				minBlockConfirmations: null,
				error: error.message,
			};
		}
	}

	// Print summary
	log(`\n=== RESULTS ===`, "measureFinalization");
	for (const [name, result] of Object.entries(results)) {
		if (result.finalityTagEnabled) {
			log(
				`✅ ${name}: finality supported, ${result.avgBlocks} blocks (${formatTime(result.avgSeconds!)}), minBlockConfirmations: ${result.minBlockConfirmations}`,
				"measureFinalization",
			);
		} else {
			log(
				`❌ ${name}: ${result.error || "finality tag not supported"}`,
				"measureFinalization",
			);
		}
	}
}

// ============================================================================
// Task Definition
// ============================================================================

/**
 * Task: measure-finalization
 * Checks finality tag support and measures finalization times for blockchain networks.
 * Determines optimal minBlockConfirmations based on average finalization time.
 *
 * @example
 * // Single network by name
 * yarn hardhat measure-finalization --networks arbitrumSepolia
 *
 * @example
 * // Multiple networks
 * yarn hardhat measure-finalization --networks "arbitrum,base,optimism"
 *
 * @example
 * // Direct RPC URL
 * yarn hardhat measure-finalization --rpcurl "https://arb1.arbitrum.io/rpc"
 *
 * @example
 * // All testnet networks with JSON output
 * yarn hardhat measure-finalization --env testnet --iterations 5 --delay 2000
 *
 * @example
 * // All mainnet networks with custom output directory
 * yarn hardhat measure-finalization --env mainnet --output ./data/
 */
task("measure-finalization", "Check finality tag support and measure finalization times")
	.addOptionalParam("networks", "Comma-separated list of networks to test")
	.addOptionalParam("rpcurl", "Direct RPC URL to test")
	.addOptionalParam(
		"env",
		"Network environment (testnet|mainnet) - checks ALL networks, writes JSON",
	)
	.addOptionalParam("output", "Output directory or file path (default: ./finality-{env}.json)")
	.addOptionalParam("iterations", "Number of samples to take", "3")
	.addOptionalParam("delay", "Delay between samples in ms", "1000")
	.setAction(handleMeasureFinalization);

export default "measure-finalization";
