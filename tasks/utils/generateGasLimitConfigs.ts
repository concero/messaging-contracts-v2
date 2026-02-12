import * as fs from "fs";
import * as path from "path";
import { encodeFunctionData } from "viem";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { ConceroNetwork, mainnetNetworks } from "@concero/contract-utils";

import { dstChainVerificationGasLimits } from "../../constants";
import { getEnvAddress, log, err, getViemAccount, getFallbackClients } from "../../utils";

interface ValidNetwork {
	network: ConceroNetwork;
	deployment: string;
}

const FUNC_NAME = "generateGasLimitConfigs";
const RELAYER_LIB_GAS_MULTIPLIER_BPS = 200n; // x2
const BPS_DENOMINATOR = 100n;
const STANDARD_TOTAL_GAS_LIMIT = 180000n; // Total gas limit observed on mainnet for the submitMessage call

const messageReceipt =
	"0x01082750000001000000000000000000000000000000000000000000000000000000000000000100001c4b198972ba7e35382aacf3a60ac7c81409b4b60600000000000000000000187349c40fd4387e899734b7519a45bd1ee908541f000493e0000001000000010000000000010000060100000186a0000000";

const validation =
	"0x018873995585334ee1b300cf653521e4fdd02c20d6ff7a823d75832cb7413a505d698c73f900000001000000010033e7b4f2904f6b584ad333d5803d67770d4693174e52bc0d668a04c53b171b353266323238396262331d218d445b69c7efa20be0dc120b8d001440f15c0001ed89e52f037f751e7e832d9c4c8d5976d86b49172fc6b68a91b9ea3a1e1ea3d1000e8ce31db48e5e44619d24d9dadfc5f22a34db8205b2b25cd831eab02244c500000000000000000000000000000000000000000000000000000000f757f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000002e00000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000180000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000415b7e32e4f3ef0ec5e9c5361ae7e2a9ff0ca0d9dae094ca7ac5e46084d4f9a15e759864dca775a8025b9e327a2d2231d31480fe12911c13969a095d2dfd1b04b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041c371833f9c251643264ea64cf22fe13d417666da4b86677fbed9f4781336cbe431a5dfd98ef3c2dacef8d5973c4a20c00f9baf451209f712ebdd27e5010f62ea01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041848c6aa104bf4b20262d113f921e4c51362f495812c3e12f1f206e4e7d5a6f0d7d40e7cf8e37897f49ec42f5bac370b093b7906d463877b9f8468a245d818c2500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000041fbf06d1e08360053fdd0779e8dea7df4ff017c32aa9c1c06250f9e6ca10a9c6140610807dd883b2fc7b8667037ddf62fe75bfd4d5cbd64647eaefedcc66be49a01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

function calculateOverheadPct(gasLimit: bigint): bigint {
	const totalGasLimit = (gasLimit * RELAYER_LIB_GAS_MULTIPLIER_BPS) / BPS_DENOMINATOR + gasLimit;
	return 100n - (STANDARD_TOTAL_GAS_LIMIT * 100n) / totalGasLimit;
}

function collectValidNetworks(): Record<string, ValidNetwork> {
	const validNetworks: Record<string, ValidNetwork> = {};

	for (const [networkName, conceroNetwork] of Object.entries(mainnetNetworks)) {
		const [deployment] = getEnvAddress("creValidatorLibProxy", networkName);

		if (!deployment) continue;

		validNetworks[networkName] = {
			network: conceroNetwork,
			deployment,
		};
	}

	return validNetworks;
}

async function estimateNetworkGasLimit(
	network: ConceroNetwork,
	deployment: string,
	callData: `0x${string}`,
): Promise<bigint> {
	const viemAccount = getViemAccount(network.type, "deployer");
	const { publicClient } = getFallbackClients(network);

	try {
		const gasLimit = await publicClient.estimateGas({
			account: viemAccount.address,
			to: deployment as `0x${string}`,
			data: callData,
		});

		log(`(${network.chainId}) Estimated gas limit: ${gasLimit}`, FUNC_NAME, network.name);
		return gasLimit;
	} catch {
		const defaultGasLimit = dstChainVerificationGasLimits.default;
		err(
			`${network.name} (${network.chainId}) Error estimating gas limit, use default ${defaultGasLimit}`,
			FUNC_NAME,
		);
		return defaultGasLimit;
	}
}

function generateGasLimitsFileContent(
	exportName: string,
	gasLimits: Record<number, bigint>,
): string {
	const entries = Object.entries(gasLimits)
		.map(([chainId, gas]) => `\t${chainId}: ${gas}n,`)
		.join("\n");

	return `// Automatically generated config - generateGasLimitConfigs.task.ts\nexport const ${exportName}: Record<number, bigint> = {\n${entries}\n}`;
}

function applyMultiplier(
	gasLimits: Record<number, bigint>,
	multiplierBps: bigint,
): Record<number, bigint> {
	const result: Record<number, bigint> = {};

	for (const [chainId, gas] of Object.entries(gasLimits)) {
		result[Number(chainId)] = (gas * multiplierBps) / BPS_DENOMINATOR;
	}

	return result;
}

function writeGasLimitFile(fileName: string, content: string): void {
	const filePath = path.resolve(__dirname, `../../constants/${fileName}.ts`);
	fs.writeFileSync(filePath, content, "utf-8");
	log(`Wrote gas limits to ${filePath}`, FUNC_NAME);
}

/**
 * Estimates on-chain gas limits for CreValidatorLib and RelayerLib, then writes them to config files.
 *
 * Gas calculation algorithm:
 * 1. CreValidatorLib: estimates gas for `isValid()` call. The estimated value includes init gas,
 *    so the actual gas consumed by `isValid` within `submitMessage` is ~60% of the estimate.
 * 2. RelayerLib: the validator gas limit is multiplied by a coefficient (e.g. x2 gives ~25% total overhead of submitMessage:
 *    validatorLibGasLimit * 2 + validatorLibGasLimit). The coefficient is derived empirically
 *    using Ethereum mainnet gas consumption as a reference.
 *    https://dashboard.tenderly.co/rlkv-concero/project/simulator/bacee9a2-a551-4946-886e-3f6b781f84c5/gas-usage
 */
export const generateGasLimitConfigs = async (hre: HardhatRuntimeEnvironment): Promise<void> => {
	const validNetworks = collectValidNetworks();
	const { abi } = hre.artifacts.readArtifactSync("EcdsaValidatorLib");

	const callData = encodeFunctionData({
		abi,
		functionName: "isValid",
		args: [messageReceipt, validation],
	});

	log(
		`Starting gas estimation with overhead around ${calculateOverheadPct(dstChainVerificationGasLimits.default)}%`,
		FUNC_NAME,
	);

	const gasLimits: Record<number, bigint> = {};
	const entries = Object.values(validNetworks);
	const results = await Promise.all(
		entries.map(({ network, deployment }) =>
			estimateNetworkGasLimit(network, deployment, callData),
		),
	);
	for (let i = 0; i < entries.length; i++) {
		gasLimits[entries[i].network.chainId] = results[i];
	}

	const successStatistics = Object.entries(gasLimits).filter(
		([_, gas]) => gas !== dstChainVerificationGasLimits.default,
	).length;

	log(
		`Succesful estimations: ${successStatistics}/${Object.keys(validNetworks).length}`,
		FUNC_NAME,
	);

	// TODO remove applyMultiplier for validatorLibGasLimits
	// when we will add mapping to RelayerLib::setSubmitMsgGasOverhead(uint24[] calldata dstChainSelectors,uint32[] calldata gasLimits)
	// it could be validatorLibGasLimits = gasLimits;
	const validatorLibGasLimits = applyMultiplier(gasLimits, 300n);

	// TODO This сalculations should remain unchanged after removing applyMultiplier for validatorLibGasLimits,
	// but remove this comment, please
	const relayerGasLimits = applyMultiplier(gasLimits, RELAYER_LIB_GAS_MULTIPLIER_BPS);

	writeGasLimitFile(
		"creValidatorLibGasLimits",
		generateGasLimitsFileContent("creValidatorLibGasLimits", validatorLibGasLimits),
	);
	writeGasLimitFile(
		"relayerLibGasLimits",
		generateGasLimitsFileContent("relayerLibGasLimits", relayerGasLimits),
	);
};
