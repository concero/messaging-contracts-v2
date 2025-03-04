import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, WalletClient, parseUnits } from "viem";

import { conceroNetworks } from "../constants";
import { getFallbackClients } from "../utils";

async function sendConceroMessage(recipientConceroClient: Address, walletClient: WalletClient) {
	const { abi: exampleClientAbi } = await import(
		"../artifacts/contracts/ConceroClient/ConceroClientExample.sol/ConceroClientExample.json"
	);

	const txHash = await walletClient.writeContract({
		address: recipientConceroClient,
		abi: exampleClientAbi,
		functionName: "sendConceroMessage",
		args: [],
		account: walletClient.account,
		value: parseUnits("0.001", 18),
	});

	console.log(`Sent concero message with txHash ${txHash}`);
}

task("send-concero-message", "Send a concero message").setAction(
	async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		const conceroNetwork = conceroNetworks[hre.network.name];
		const { walletClient } = getFallbackClients(conceroNetwork);
		const recipientConceroClient = "0x1234567890123456789012345678901234567890";

		await sendConceroMessage(recipientConceroClient, walletClient);
	},
);

export { sendConceroMessage };
