import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { encodeFunctionData } from "viem";

import { ProxyEnum } from "../../constants";
import { deployProxyAdmin, deployRouter, deployTransparentProxy } from "../../deploy";
import deployRelayerLib from "../../deploy/RelayerLib";
import { getViemAccount } from "../../utils";
import { compileContracts } from "../../utils/compileContracts";
import { upgradeProxyImplementation } from "../utils";
import { setRelayerLibVars } from "./setRelayerLibVars";
import { setRouterVariables } from "./setRouterVariables";

async function deployRelayerLibTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployRelayerLib(hre);
	}

	if (taskArgs.proxy) {
		await deployProxyAdmin(hre, ProxyEnum.relayerLibProxy);

		const { abi } = await import(
			"../../artifacts/contracts/validators/CreValidatorLib/CreValidatorLib.sol/CreValidatorLib.json"
		);
		const privateKeyAccount = getViemAccount("testnet", "deployer");
		const initializerCallData = encodeFunctionData({
			abi,
			functionName: "initialize",
			args: [privateKeyAccount.address],
		});

		await deployTransparentProxy(hre, ProxyEnum.relayerLibProxy, initializerCallData);
	}

	if (taskArgs.implementation) {
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
