import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum } from "../../constants";
import { deployProxyAdmin, deployRouter, deployTransparentProxy } from "../../deploy";
import { compileContracts } from "../../utils/compileContracts";
import { upgradeProxyImplementation } from "../utils";
import { setRouterVariables } from "./setRouterVariables";

async function deployRouterTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployRouter(hre);
	}

	//todo: when running --deployproxy W/O --deployimplementation,

	if (taskArgs.proxy) {
		await deployProxyAdmin(hre, ProxyEnum.routerProxy);
		await deployTransparentProxy(hre, ProxyEnum.routerProxy);
	}

	if (taskArgs.implementation) {
		await upgradeProxyImplementation(hre, ProxyEnum.routerProxy, false);
	}

	if (taskArgs.vars) {
		await setRouterVariables(hre);
	}
}

task("deploy-router", "Deploy ConceroRouter")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.addFlag("vars", "Set contract variables")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployRouterTask(taskArgs, hre);
	});

export { deployRouterTask };
