import { getNetworkEnvKey } from "@concero/contract-utils";
import { Address } from "viem";

import { ConceroTestnetNetworkNames, conceroNetworks } from "../../constants/conceroNetworks";
import { getEnvVar, getFallbackClients, log } from "../../utils";

const relayer = "0x51aa24026e9367987e931caabd6519fb491a274a";

export async function setRelayerLibVars(conceroNetworkName: ConceroTestnetNetworkNames) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];

	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const relayerLib = getEnvVar(
		`CONCERO_RELAYER_LIB_${getNetworkEnvKey(conceroNetworkName)}`,
	) as Address;
	const { abi: relayerLibAbi } = await import(
		"../../artifacts/contracts/relayers/RelayerLib/RelayerLib.sol/RelayerLib.json"
	);

	const isRelayerAllowed = await publicClient.readContract({
		address: relayerLib,
		abi: relayerLibAbi,
		functionName: "isAllowedRelayer",
		args: [relayer],
	});

	if (isRelayerAllowed === true) return;

	const hash = await walletClient.writeContract({
		address: relayerLib,
		abi: relayerLibAbi,
		functionName: "setRelayers",
		args: [[relayer], [true]],
	});

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setRelayers", conceroNetworkName);
}
