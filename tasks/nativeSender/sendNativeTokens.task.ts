import { nonceManager } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import { task } from "hardhat/config";

import { getEnvVar } from "../../utils";
import { NativeTokenSender } from "./NativeTokenSender";

async function sendNativeTokensTask(taskArgs: any) {
	const transactionGasLimit = 1000000n;
	const chainNames = taskArgs.networks.split(",").map((n: string) => n.trim());
	const privateKey = getEnvVar("TESTNET_DEPLOYER_PRIVATE_KEY");

	if (!privateKey) {
		throw new Error("DONOR_PRIVATE_KEY is not set");
	}
	const senderAccount = privateKeyToAccount(`0x${privateKey}`, {
		nonceManager: nonceManager,
	});

	const nativeSender = new NativeTokenSender(
		senderAccount,
		transactionGasLimit,
		taskArgs.testnet,
	);

	if (!taskArgs.recipient) {
		throw new Error("Recipient address is required");
	}

	if (!taskArgs.networks) {
		throw new Error("Networks are required");
	}

	if (taskArgs.amount) {
		await nativeSender.sendByAmount(taskArgs.recipient, taskArgs.amount, chainNames);
	}

	if (taskArgs.txcount) {
		await nativeSender.sendByTransactionCount(
			taskArgs.recipient,
			Number(taskArgs.txcount),
			chainNames,
		);
	}
}

task("send-native-tokens", "Send native tokens to specified address on multiple networks")
	.addFlag("testnet", "Use testnet instead of mainnet")
	.addParam("recipient", "Recipient address")
	.addParam("networks", "Comma-separated list of network names (e.g., 'sepolia,polygonAmoy')")
	.addOptionalParam("amount", "Amount of native tokens to send in ETH (e.g. 0.001 ETH)")
	.addOptionalParam(
		"txcount",
		"Amount of native tokens that will cover the transaction number cost",
	)
	.setAction(async taskArgs => {
		await sendNativeTokensTask(taskArgs);
	});

export { sendNativeTokensTask };
