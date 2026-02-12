import {
	conceroNetworks,
	ConceroTestnetNetworkNames,
	trezorWriteContract,
} from "@concero/contract-utils";
import { Address, Hash } from "viem";

import {
	getEnvVar,
	getFallbackClients,
	getNetworkEnvKey,
	getTrezorDeployEnabled,
	log,
} from "../../utils";
import { isDeployToStage } from "../../utils/isDeployToStage";

export const testnetRelayer = "0x51aa24026e9367987e931caabd6519fb491a274a";
export const stageRelayer = "0xd56489a60D9675dD5e5924fB685a4F2CBb1DFAC0";
export const mainnetRelayer = "0x22BdE89606d9316404a21ff7ABb63ADCE506D198";

export async function setIsAllowedRelayer(conceroNetworkName: ConceroTestnetNetworkNames) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];
	const hre = require("hardhat");

	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const relayerLib = getEnvVar(
		`CONCERO_RELAYER_LIB_PROXY_${getNetworkEnvKey(conceroNetworkName)}`,
	) as Address;

	const { abi: relayerLibAbi } = hre.artifacts.readArtifactSync("RelayerLib");

	const relayer =
		conceroNetwork.type === "mainnet"
			? mainnetRelayer
			: isDeployToStage()
				? stageRelayer
				: testnetRelayer;

	const isRelayerAllowed = await publicClient.readContract({
		address: relayerLib,
		abi: relayerLibAbi,
		functionName: "isAllowedRelayer",
		args: [relayer],
	});

	if (isRelayerAllowed === true) return;

	log(`Setting relayer: ${relayer}`, conceroNetworkName);

	let hash: Hash;

	const functionArgs = [[relayer], [true]];
	const writeContractParams = {
		address: relayerLib,
		abi: relayerLibAbi,
		functionName: "setRelayers",
		args: functionArgs,
	};

	if (getTrezorDeployEnabled()) {
		hash = await trezorWriteContract({ publicClient }, writeContractParams);
	} else {
		hash = await walletClient.writeContract(writeContractParams);
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setRelayers", conceroNetworkName);
}

export async function setSubmitMsgGasOverhead(conceroNetworkName: ConceroTestnetNetworkNames) {
	// TODO - set submit msg gas overhead when we add mapping to RelayerLib smart-contract
	// use ../../constants/relayerLibGasLimits.ts
}

export async function setRelayerLibVars(conceroNetworkName: ConceroTestnetNetworkNames) {
	await setIsAllowedRelayer(conceroNetworkName);
	await setSubmitMsgGasOverhead(conceroNetworkName);
}
