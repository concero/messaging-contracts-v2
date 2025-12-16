import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum } from "../../constants";
import { deployRouter, deployTransparentProxy } from "../../deploy";
import { compileContracts } from "../../utils";
import { upgradeProxyImplementation } from "../utils";

async function deployRouterTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployRouter(hre);
	}

	if (taskArgs.proxy) {
		await deployTransparentProxy(hre, ProxyEnum.routerProxy);
	}

	if (taskArgs.implementation && !taskArgs.proxy) {
		await upgradeProxyImplementation(hre, ProxyEnum.routerProxy, false);
	}
}

task("deploy-router", "Deploy ConceroRouter")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployRouterTask(taskArgs, hre);
	});

export { deployRouterTask };
