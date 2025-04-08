import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";
import { getClients } from "../utils";

task("fetch-transaction-info", "")
	.addParam("hash", "")
	.setAction(async taskArgs => {
		const hre = require("hardhat");
		const conceroNetwork = conceroNetworks[hre.network.name];

		const { publicClient } = getClients(conceroNetwork.viemChain);
		const tx = await publicClient.waitForTransactionReceipt({ hash: taskArgs.hash });

		console.log(tx);
	});

export default {};
