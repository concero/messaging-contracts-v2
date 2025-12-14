import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, encodeFunctionData } from "viem";

import { ProxyEnum } from "../../constants";
import { deployProxyAdmin, deployTransparentProxy } from "../../deploy";
import deployRelayerLib from "../../deploy/RelayerLib";
import { compileContracts } from "../../utils";
import { upgradeProxyImplementation } from "../utils";
import { setRelayerLibVars } from "./setRelayerLibVars";

async function deployRelayerLibTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployRelayerLib(hre);
	}

	if (taskArgs.proxy) {
		await deployProxyAdmin(hre, ProxyEnum.relayerLibProxy);

		const { abi } = hre.artifacts.readArtifactSync("CreValidatorLib");
		const [ethersSigner] = await hre.ethers.getSigners();

		const initializerCallData = encodeFunctionData({
			abi,
			functionName: "initialize",
			args: [ethersSigner.address as Address],
		});

		await deployTransparentProxy(hre, ProxyEnum.relayerLibProxy, initializerCallData);
	}

	if (taskArgs.implementation && !taskArgs.proxy) {
		await upgradeProxyImplementation(hre, ProxyEnum.relayerLibProxy, false);
	}

	if (taskArgs.vars) {
		await setRelayerLibVars(hre.network.name);
	}
}

task("deploy-relayer-lib", "")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.addFlag("vars", "Set contract variables")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployRelayerLibTask(taskArgs, hre);
	});

export { deployRelayerLibTask };
