import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum, conceroNetworks } from "../../constants";
import { deployTransparentProxy, deployVerifier } from "../../deploy/";
import { compileContracts } from "../../utils";
import { getEnvAddress } from "../../utils/";
import { addCLFConsumer } from "../clf";
import { upgradeProxyImplementation } from "../utils/";
import { setVerifierVariables } from "./setVerifierVariables";

async function deployVerifierTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });
	const conceroNetwork = conceroNetworks[hre.network.name];

	if (taskArgs.proxy) {
		await deployTransparentProxy(hre, ProxyEnum.verifierProxy);
		const [proxyAddress] = getEnvAddress(ProxyEnum.verifierProxy, hre.network.name);
		await addCLFConsumer(conceroNetwork, [proxyAddress]);
	}

	if (taskArgs.implementation) {
		await deployVerifier(hre);
		await upgradeProxyImplementation(hre, ProxyEnum.verifierProxy, false);
	}

	if (taskArgs.vars) {
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
