import { parseEther } from "viem";

import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";
import { getFallbackClients } from "../utils";

task("send-value")
	.addParam("recipient")
	.addParam("value")
	.setAction(async (taskArgs, hre) => {
		const conceroNetwork = conceroNetworks[hre.network.name];

		const { walletClient, publicClient } = getFallbackClients(conceroNetwork);

		const hash = await walletClient.sendTransaction({
			account: walletClient.account,
			value: parseEther(taskArgs.value),
			to: taskArgs.recipient,
		});

		const { status } = await publicClient.waitForTransactionReceipt({ hash });

		console.log(hash, status);
	});

export default {};
