import { task } from "hardhat/config";
import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum } from "../../constants";
import { deployProxyAdmin, deployRouter, deployTransparentProxy } from "../../deploy";
import { compileContracts } from "../../utils/compileContracts";
import { upgradeProxyImplementation } from "../utils";
import { setRouterVariables } from "./setRouterVariables";

async function deployRouterTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	//todo: when running --deployproxy W/O --deployimplementation,
	//the initial proxy implementation is set to paused, but should be set to existing latest impl. from env.
	if (taskArgs.deployproxy) {
		await deployProxyAdmin(hre, ProxyEnum.routerProxy);
		await deployTransparentProxy(hre, ProxyEnum.routerProxy);
	}

	if (taskArgs.deployimplementation) {
		await deployRouter(hre);
		await upgradeProxyImplementation(hre, ProxyEnum.routerProxy, false);
	}

	if (taskArgs.setvars) {
		await setRouterVariables(hre);
	}
}

task("deploy-router", "Deploy the ConceroRouter contract")
	.addFlag("deployproxy", "Deploy the proxy")
	.addFlag("deployimplementation", "Deploy the implementation")
	.addFlag("setvars", "Set the contract variables")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployRouterTask(taskArgs, hre);
	});

export { deployRouterTask };
