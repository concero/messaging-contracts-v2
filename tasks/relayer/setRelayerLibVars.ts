import { getNetworkEnvKey } from "@concero/contract-utils";
import { Address, Hash } from "viem";

import { ConceroTestnetNetworkNames, conceroNetworks } from "../../constants/conceroNetworks";
import { getEnvVar, getFallbackClients, log } from "../../utils";
import { getTrezorDeployEnabled } from "../../utils/getTrezorDeployEnabled";

const relayer = "0x51aa24026e9367987e931caabd6519fb491a274a";

export async function setRelayerLibVars(conceroNetworkName: ConceroTestnetNetworkNames) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];
	const hre = require("hardhat");

	const [ethersSigner] = await hre.ethers.getSigners();

	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const relayerLib = getEnvVar(
		`CONCERO_RELAYER_LIB_PROXY_${getNetworkEnvKey(conceroNetworkName)}`,
	) as Address;
	// const { abi: relayerLibAbi } = await import(
	// 	"../../artifacts/contracts/relayers/RelayerLib/RelayerLib.sol/RelayerLib.json"
	// );

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
		const contract = hre.ethers.Contract(relayerLib, relayerLibAbi, ethersSigner);
		const unsignedTx = await contract.setRelayers.populateTransaction(functionArgs);
		const signedTx = await ethersSigner.signTransaction(unsignedTx);
		hash = await publicClient.sendRawTransaction({ serializedTransaction: signedTx });
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
