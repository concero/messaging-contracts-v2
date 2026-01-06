import { task } from "hardhat/config";

import { getLastGasPrice } from "./utils/getLastGasPrice";

async function getLastGasPriceTask(taskArgs: any) {
	await getLastGasPrice(taskArgs.chains, taskArgs.src, taskArgs.testnet);
}

// yarn hardhat get-last-gas-price --chains arbitrumSepolia,avalancheFuji --testnet --src arbitrumSepolia
// yarn hardhat get-last-gas-price --testnet
// yarn hardhat get-last-gas-price
task("get-last-gas-price", "Get last gas price from the ConceroPriceFeed")
	.addFlag("testnet", "Use testnet instead of mainnet")
	.addOptionalParam("src", "Source chain to get last gas price from")
	.addOptionalParam("chains", "Comma separated list of chains to get last gas price from", "")
	.setAction(async taskArgs => {
		await getLastGasPriceTask(taskArgs);
	});

export { getLastGasPriceTask };
