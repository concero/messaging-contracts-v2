import { getNetworkEnvKey } from "@concero/contract-utils";
import { Address } from "viem";

import { conceroNetworks } from "../../constants";
import { getEnvVar, getFallbackClients, log } from "../../utils";

const MAX_VALIDATORS_COUNT = 20;

export async function setMaxAllowedValidators(networkName: string) {
	const network = conceroNetworks[networkName];

	const { abi: conceroRouterAbi } = await import(
		"../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);
	const conceroRouter = getEnvVar(
		`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(networkName)}`,
	) as Address;

	const { walletClient, publicClient } = getFallbackClients(network);

	const functionName = "setMaxValidatorsCount";
	const hash = await walletClient.writeContract({
		address: conceroRouter,
		abi: conceroRouterAbi,
		functionName: functionName,
		args: [MAX_VALIDATORS_COUNT],
		gas: 100_000n,
	});

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	console.log(status, hash);

	log(`${status} ${MAX_VALIDATORS_COUNT}`, functionName, networkName);
}
