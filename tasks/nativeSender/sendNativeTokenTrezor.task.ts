import { task } from "hardhat/config";

import { log } from "@concero/contract-utils";
import { parseUnits } from "viem";

async function sendNativeTokenTrezor(taskArgs: any) {
	const hre = require("hardhat");
	let [signer] = await hre.ethers.getSigners();

	log(`Sending value from ${signer.address}`, "sendValueTrezor");

	const tx = await signer.sendTransaction({
		to: taskArgs.recipient,
		value: parseUnits(taskArgs.amount, 18),
	});

	const receipt = await tx.wait();

	log(`${receipt?.status === 1 ? "success" : "reverted"}: ${receipt.hash}`, "sendValueTrezor");
}

// TODO: mb merge with sendNativeToken task
task("send-native-token-trezor", "Send native tokens to specified address on multiple networks")
	.addParam("recipient", "Recipient address")
	.addOptionalParam("amount", "Amount of native tokens to send in ETH (e.g. 0.001 ETH)")
	.addOptionalParam("percent", "Percent of account balance to send")
	.setAction(async taskArgs => {
		await sendNativeTokenTrezor(taskArgs);
	});

export default {};
