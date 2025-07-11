import { task } from "hardhat/config";
import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ConceroNetwork } from "@concero/contract-utils";

import { ProxyEnum } from "../../constants";
import { conceroNetworks } from "../../constants";
import { Namespaces } from "../../constants/storage/ConceroVerifierStorage";
import { getEnvAddress, getFallbackClients, log } from "../../utils";

interface VerifierGasFeeConfig {
	vrfMsgReportRequestGasOverhead: number;
	clfGasPriceOverEstimationBps: number;
	clfCallbackGasOverhead: number;
	clfCallbackGasLimit: number;
}

export async function readVerifierGasFeeConfig(
	network: ConceroNetwork,
): Promise<VerifierGasFeeConfig | null> {
	const { publicClient } = getFallbackClients(network);
	const [conceroVerifierAddress] = getEnvAddress(ProxyEnum.verifierProxy, network.name);

	try {
		// Fallback to storage reading
		const configSlot = Namespaces.CONFIG;
		const storageValue = await publicClient.getStorageAt({
			address: conceroVerifierAddress,
			slot: configSlot,
		});

		if (
			!storageValue ||
			storageValue === "0x0000000000000000000000000000000000000000000000000000000000000000"
		) {
			log("VerifierGasFeeConfig not set or empty", "readVerifierGasFeeConfig", network.name);
			return null;
		}

		// Manual decoding of packed struct
		// GasFeeConfig is packed in storage: uint32 + uint32 + uint32 + uint32 + uint160
		// Based on the raw storage value, fields are packed right-to-left (little-endian)
		const hexValue = storageValue.slice(2); // Remove '0x' prefix

		// Convert hex to bigint for easier bit manipulation
		const value = BigInt("0x" + hexValue);

		// Extract fields using bit operations (right-to-left based on actual storage layout)
		// Storage layout: [padding][clfCallbackGasLimit][clfCallbackGasOverhead][clfGasPriceOverEstimationBps][vrfMsgReportRequestGasOverhead]
		const vrfMsgReportRequestGasOverhead = Number(value & 0xffffffffn); // First 32 bits (bits 0-31)
		const clfGasPriceOverEstimationBps = Number((value >> 32n) & 0xffffffffn); // Next 32 bits (bits 32-63)
		const clfCallbackGasOverhead = Number((value >> 64n) & 0xffffffffn); // Next 32 bits (bits 64-95)
		const clfCallbackGasLimit = Number((value >> 96n) & 0xffffffffn); // Next 32 bits (bits 96-127)
		// __var_gap and padding occupy the remaining bits

		const gasFeeConfig: VerifierGasFeeConfig = {
			vrfMsgReportRequestGasOverhead,
			clfGasPriceOverEstimationBps,
			clfCallbackGasOverhead,
			clfCallbackGasLimit,
		};

		return gasFeeConfig;
	} catch (error) {
		log(
			`Error reading verifierGasFeeConfig: ${(error as Error).message}`,
			"readVerifierGasFeeConfig",
			network.name,
		);
		return null;
	}
}

export async function displayVerifierGasFeeConfig(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;
	const network = conceroNetworks[name as keyof typeof conceroNetworks] as ConceroNetwork;

	if (!network) {
		log(`Network ${name} not found in conceroNetworks`, "displayVerifierGasFeeConfig");
		return;
	}

	const gasFeeConfig = await readVerifierGasFeeConfig(network);

	if (!gasFeeConfig) {
		log(
			"❌ VerifierGasFeeConfig not found or not set",
			"displayVerifierGasFeeConfig",
			network.name,
		);
		return;
	}

	console.log(
		`\n VerifierGasFeeConfig Settings for ${network.name} (chainId: ${network.chainId}):`,
	);
	console.log(`- vrfMsgReportRequestGasOverhead: ${gasFeeConfig.vrfMsgReportRequestGasOverhead}`);
	console.log(`- clfGasPriceOverEstimationBps: ${gasFeeConfig.clfGasPriceOverEstimationBps}`);
	console.log(`- clfCallbackGasOverhead: ${gasFeeConfig.clfCallbackGasOverhead}`);
	console.log(`- clfCallbackGasLimit: ${gasFeeConfig.clfCallbackGasLimit} \n`);

	log("✅ VerifierGasFeeConfig read successfully", "displayVerifierGasFeeConfig", network.name);
}

task(
	"read-verifier-gas-fee-config",
	"Reads and displays the current GasFeeConfig from ConceroVerifier contract",
).setAction(async (taskArgs, hre) => {
	await displayVerifierGasFeeConfig(hre);
});
