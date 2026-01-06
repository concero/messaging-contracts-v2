import { task } from "hardhat/config";

import { getNativeUsdRate } from "./utils/getNativeUsdRate";

async function getNativeUsdRateTask(taskArgs: any) {
	await getNativeUsdRate(taskArgs.chains, taskArgs.testnet, taskArgs.errors);
}

// yarn hardhat get-native-usd-rate --chains arbitrumSepolia,avalancheFuji --testnet --errors
// yarn hardhat get-native-usd-rate --testnet
// yarn hardhat get-native-usd-rate
task("get-native-usd-rate", "Get native USD rate from the ConceroPriceFeed")
	.addFlag("testnet", "Use testnet instead of mainnet")
	.addFlag("errors", "Show full error messages")
	.addOptionalParam("chains", "Comma separated list of chains to get native USD rate from", "")
	.setAction(async taskArgs => {
		await getNativeUsdRateTask(taskArgs);
	});

export { getNativeUsdRateTask };