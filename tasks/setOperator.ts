import { parseAbi } from "viem";

import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";
import { getEnvAddress, getFallbackClients } from "../utils";

task("set-operator", "Set price feeds for the router").setAction(async (_, hre) => {
	const [verifierProxy] = getEnvAddress("verifierProxy", hre.network.name);
	const conceroNetwork = conceroNetworks[hre.network.name];
	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const operator = "0xeee38505c47acba0c866df7265bd3e25da596b27";

	const setOperatorHash = await walletClient.writeContract({
		account: walletClient.account,
		address: verifierProxy,
		abi: parseAbi(["function setOperator(address) external"]),
		functionName: "setOperator",
		args: [operator],
	});

	const setOperatorStatus = (
		await publicClient.waitForTransactionReceipt({
			hash: setOperatorHash,
		})
	).status;

	console.log(`tx ${setOperatorStatus}: `, setOperatorHash);
});

export default {};
