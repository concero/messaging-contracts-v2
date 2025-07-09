import { task } from "hardhat/config";
import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ConceroNetwork } from "@concero/contract-utils";

import { ProxyEnum } from "../../constants";
import { conceroNetworks } from "../../constants";
import { Namespaces } from "../../constants/storage/ConceroRouterStorage";
import { getEnvAddress, getFallbackClients, log } from "../../utils";

interface GasFeeConfig {
	baseChainSelector: number;
	submitMsgGasOverhead: number;
	vrfMsgReportRequestGasLimit: number;
	vrfCallbackGasLimit: number;
}

export async function readGasFeeConfig(network: ConceroNetwork): Promise<GasFeeConfig | null> {
	const { publicClient } = getFallbackClients(network);
	const [conceroRouterAddress] = getEnvAddress(ProxyEnum.routerProxy, network.name);

	try {
		// Fallback to storage reading
		const configSlot = Namespaces.CONFIG;
		const storageValue = await publicClient.getStorageAt({
			address: conceroRouterAddress,
			slot: configSlot,
		});

		if (
			!storageValue ||
			storageValue === "0x0000000000000000000000000000000000000000000000000000000000000000"
		) {
			log("GasFeeConfig not set or empty", "readGasFeeConfig", network.name);
			return null;
		}

		// Manual decoding of packed struct
		// GasFeeConfig is packed in storage: uint24 + uint32 + uint32 + uint32 + uint136
		// Based on the raw storage value, fields are packed right-to-left (little-endian)
		const hexValue = storageValue.slice(2); // Remove '0x' prefix

		// Convert hex to bigint for easier bit manipulation
		const value = BigInt("0x" + hexValue);

		// Extract fields using bit operations (right-to-left based on actual storage layout)
		// Storage layout: [padding][vrfCallbackGasLimit][vrfMsgReportRequestGasLimit][submitMsgGasOverhead][baseChainSelector]
		const baseChainSelector = Number(value & 0xffffffn); // Last 24 bits (bits 0-23)
		const submitMsgGasOverhead = Number((value >> 24n) & 0xffffffffn); // Next 32 bits (bits 24-55)
		const vrfMsgReportRequestGasLimit = Number((value >> 56n) & 0xffffffffn); // Next 32 bits (bits 56-87)
		const vrfCallbackGasLimit = Number((value >> 88n) & 0xffffffffn); // Next 32 bits (bits 88-119)
		// __var_gap and padding occupy the remaining bits

		const gasFeeConfig: GasFeeConfig = {
			baseChainSelector,
			submitMsgGasOverhead,
			vrfMsgReportRequestGasLimit,
			vrfCallbackGasLimit,
		};

		return gasFeeConfig;
	} catch (error) {
		log(
			`Error reading gasFeeConfig: ${(error as Error).message}`,
			"readGasFeeConfig",
			network.name,
		);
		return null;
	}
}

export async function displayGasFeeConfig(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;
	const network = conceroNetworks[name as keyof typeof conceroNetworks] as ConceroNetwork;

	if (!network) {
		log(`Network ${name} not found in conceroNetworks`, "displayGasFeeConfig");
		return;
	}

	const gasFeeConfig = await readGasFeeConfig(network);

	if (!gasFeeConfig) {
		log("❌ GasFeeConfig not found or not set", "displayGasFeeConfig", network.name);
		return;
	}

	console.log(`\n GasFeeConfig Settings for ${network.name} (chainId: ${network.chainId}):`);
	console.log(`- baseChainSelector: ${gasFeeConfig.baseChainSelector}`);
	console.log(`- submitMsgGasOverhead: ${gasFeeConfig.submitMsgGasOverhead}`);
	console.log(`- vrfMsgReportRequestGasLimit: ${gasFeeConfig.vrfMsgReportRequestGasLimit}`);
	console.log(`- vrfCallbackGasLimit: ${gasFeeConfig.vrfCallbackGasLimit} \n`);

	log("✅ GasFeeConfig read successfully", "displayGasFeeConfig", network.name);
}

task(
	"read-gas-fee-config",
	"Reads and displays the current GasFeeConfig from ConceroRouter contract",
).setAction(async (taskArgs, hre) => {
	await displayGasFeeConfig(hre);
});
