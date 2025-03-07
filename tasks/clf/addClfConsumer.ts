import { Address } from "viem";

import { SubscriptionManager } from "@chainlink/functions-toolkit";

import { networkEnvKeys } from "../../constants";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { getEnvVar, log } from "../../utils";

export async function addCLFConsumer(chain: ConceroNetwork, consumerAddresses: Address[]) {
	const hre = require("hardhat");
	const { confirmations, name } = chain;
	const adminAddress = process.env.TESTNET_DEPLOYER_ADDRESS;
	const signer = await hre.ethers.getSigner(adminAddress);
	const subscriptionId = getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`);

	for (const consumerAddress of consumerAddresses) {
		log(`Adding ${consumerAddress} to sub ${subscriptionId} on ${name}`, "addCLFConsumer");

		const txOptions = { confirmations };
		const linkTokenAddress = getEnvVar(`LINK_${networkEnvKeys[name]}`);
		const sm = new SubscriptionManager({
			signer,
			linkTokenAddress,
			functionsRouterAddress: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
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
