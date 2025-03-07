import { task } from "hardhat/config";
import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum, conceroNetworks } from "../../constants";
import { deployProxyAdmin, deployTransparentProxy, deployVerifier } from "../../deploy/";
import { getEnvAddress } from "../../utils/";
import { compileContracts } from "../../utils/compileContracts";
import { addCLFConsumer } from "../clf";
import { upgradeProxyImplementation } from "../utils/";
import { setVerifierVariables } from "./setVerifierVariables";

async function deployVerifierTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });
	const conceroNetwork = conceroNetworks[hre.network.name];

	if (taskArgs.deployproxy) {
		await deployProxyAdmin(hre, ProxyEnum.clfRouterProxy);
		await deployTransparentProxy(hre, ProxyEnum.clfRouterProxy);
		const [proxyAddress] = getEnvAddress(ProxyEnum.clfRouterProxy, hre.network.name);
		await addCLFConsumer(conceroNetwork, [proxyAddress]);
	}

	if (taskArgs.deployimplementation) {
		await deployVerifier(hre);
		await upgradeProxyImplementation(hre, ProxyEnum.clfRouterProxy, false);
	}

	if (taskArgs.setvars) {
		await setVerifierVariables(hre);
	}
}

task("deploy-verifier", "Deploy ConceroVerifier")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.addFlag("vars", "Set contract variables")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployVerifierTask(taskArgs, hre);
	});

export { deployVerifierTask };
