import { SubscriptionManager } from "@chainlink/functions-toolkit";
import { Address } from "viem";

import { ConceroNetwork } from "../../types/ConceroNetwork";
import { getEnvVar, log } from "../../utils";

export async function addCLFConsumer(chain: ConceroNetwork, consumerAddresses: Address[]) {
	const hre = require("hardhat");
	const { confirmations, name } = chain;
	const adminAddress = process.env.TESTNET_DEPLOYER_ADDRESS;
	const signer = await hre.ethers.getSigner(adminAddress);
	const subscriptionId = getEnvVar(`CLF_SUBID_${getNetworkEnvKey(name)}`);

	for (const consumerAddress of consumerAddresses) {
		log(`Adding ${consumerAddress} to sub ${subscriptionId} on ${name}`, "addCLFConsumer");

		const txOptions = { confirmations };
		const linkTokenAddress = getEnvVar(`LINK_${getNetworkEnvKey(name)}`);
		const sm = new SubscriptionManager({
			signer,
			linkTokenAddress,
			functionsRouterAddress: getEnvVar(`CLF_ROUTER_${getNetworkEnvKey(name)}`),
		});

		// await sm.estimateFunctionsRequestCost({ subscriptionId, consumerAddress, txOptions });
		await sm.initialize();

		try {
			await sm.addConsumer({ subscriptionId, consumerAddress, txOptions });
			log(
				`Successfully added ${consumerAddress} to sub ${subscriptionId} on ${name}.`,
				"addCLFConsumer",
			);
		} catch (error) {
			if (error.message.includes("is already authorized to use subscription")) {
				log(error.message, "addCLFConsumer");
			} else {
				console.error(error);
			}
		}
	}
}
