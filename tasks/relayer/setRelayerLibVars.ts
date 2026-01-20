import { Address, Hash } from "viem";

import { ConceroTestnetNetworkNames, conceroNetworks } from "../../constants/conceroNetworks";
import { getEnvVar, getFallbackClients, log } from "../../utils";
import { getNetworkEnvKey, getTrezorDeployEnabled } from "../../utils";
import { ethersSignerCallContract } from "../utils/ethersSignerCallContract";

const relayer = "0x51aa24026e9367987e931caabd6519fb491a274a";

export async function setRelayerLibVars(conceroNetworkName: ConceroTestnetNetworkNames) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];
	const hre = require("hardhat");

	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const relayerLib = getEnvVar(
		`CONCERO_RELAYER_LIB_PROXY_${getNetworkEnvKey(conceroNetworkName)}`,
	) as Address;

	const { abi: relayerLibAbi } = hre.artifacts.readArtifactSync("RelayerLib");

	const isRelayerAllowed = await publicClient.readContract({
		address: relayerLib,
		abi: relayerLibAbi,
		functionName: "isAllowedRelayer",
		args: [relayer],
	});

	if (isRelayerAllowed === true) return;
	let hash: Hash;
	const functionArgs = [[relayer], [true]];

	if (getTrezorDeployEnabled()) {
		hash = await ethersSignerCallContract(
			hre,
			relayerLib,
			relayerLibAbi,
			"setRelayers",
			...functionArgs,
		);
	} else {
		hash = await walletClient.writeContract({
			address: relayerLib,
			abi: relayerLibAbi,
			functionName: "setRelayers",
			args: functionArgs,
		});
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setRelayers", conceroNetworkName);
}
