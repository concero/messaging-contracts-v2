import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum } from "../../constants";
import { deployPriceFeed, deployTransparentProxy } from "../../deploy";
import { compileContracts } from "../../utils";
import { upgradeProxyImplementation } from "../utils";

async function deployPriceFeedTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployPriceFeed(hre);
	}

	if (taskArgs.proxy) {
		await deployTransparentProxy(hre, ProxyEnum.priceFeedProxy);
	}

	if (taskArgs.implementation) {
		await upgradeProxyImplementation(hre, ProxyEnum.priceFeedProxy, false);
	}
}

task("deploy-price-feed", "Deploy ConceroPriceFeed")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployPriceFeedTask(taskArgs, hre);
	});

export { deployPriceFeedTask };
