import { task } from "hardhat/config";
import { conceroNetworks, getFallbackClients, log, trezorSendTx } from "@concero/contract-utils";
import { parseUnits } from "viem";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export async function sendNativeTokenTrezor(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	const { publicClient } = getFallbackClients(conceroNetworks[hre.network.name]);

	const hash = await trezorSendTx(
		{ publicClient },
		{
			to: taskArgs.recipient,
			value: parseUnits(taskArgs.amount, 18),
		},
	);

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(`${status}: ${hash}`, "sendValueTrezor");
}

// TODO: mb merge with sendNativeToken task
task("send-native-token-trezor", "Send native tokens to specified address on multiple networks")
	.addParam("recipient", "Recipient address")
	.addOptionalParam("amount", "Amount of native tokens to send in ETH (e.g. 0.001 ETH)")
	.addOptionalParam("percent", "Percent of account balance to send")
	.setAction(async (taskArgs, hre) => {
		await sendNativeTokenTrezor(taskArgs, hre);
	});

export default {};
