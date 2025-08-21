import { task } from "hardhat/config";

import { withdrawMessageFees } from "./utils/withdrawMessageFees";

async function withdrawMessageFeesTask(taskArgs: any) {
	await withdrawMessageFees(taskArgs.chains, taskArgs.testnet, taskArgs.errors);
}

// yarn hardhat withdraw-message-fee --chains arbitrumSepolia,avalancheFuji --testnet --errors
// yarn hardhat withdraw-message-fee --testnet
// yarn hardhat withdraw-message-fee
task("withdraw-message-fee", "Withdraw message fees from the ConceroRouter")
	.addFlag("testnet", "Use testnet instead of mainnet")
	.addFlag("errors", "Show full error messages")
	.addOptionalParam("chains", "Comma separated list of chains to withdraw fees from", "")
	.setAction(async taskArgs => {
		await withdrawMessageFeesTask(taskArgs);
	});

export { withdrawMessageFeesTask };
