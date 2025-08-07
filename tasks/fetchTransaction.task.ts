import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";
import { getFallbackClients } from "../utils";

task("fetch-transaction-info", "")
	.addParam("hash", "")
	.setAction(async taskArgs => {
		const hre = require("hardhat");
		const conceroNetwork = conceroNetworks[hre.network.name];

		const { publicClient } = getFallbackClients(conceroNetwork);
		const tx = await publicClient.getTransaction({ hash: taskArgs.hash });

		console.log(tx);
	});

export default {};
