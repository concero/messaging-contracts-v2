import { task } from "hardhat/config";

import { getNativeNativeRate } from "./utils/getNativeNativeRate";

async function getNativeNativeRateTask(taskArgs: any) {
	await getNativeNativeRate(taskArgs.src, taskArgs.chains, taskArgs.testnet);
}

// yarn hardhat get-native-native-rate --src arbitrumSepolia --chains baseSepolia,bnbTestnet --testnet
// yarn hardhat get-native-native-rate --src arbitrumSepolia --testnet
// yarn hardhat get-native-native-rate --src arbitrum
task("get-native-native-rate", "Get native-native rate from the ConceroPriceFeed")
	.addFlag("testnet", "Use testnet instead of mainnet")
	.addParam("src", "Source chain to get native-native rate from (required)")
	.addOptionalParam("chains", "Comma separated list of chains to get native-native rate for", "")
	.setAction(async taskArgs => {
		await getNativeNativeRateTask(taskArgs);
	});

export { getNativeNativeRateTask };
