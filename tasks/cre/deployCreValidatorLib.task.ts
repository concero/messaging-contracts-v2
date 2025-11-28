import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { encodeFunctionData } from "viem";

import { ProxyEnum } from "../../constants";
import { deployProxyAdmin, deployTransparentProxy } from "../../deploy";
import deployConceroCreValidatorLib from "../../deploy/CocneroCreValidatorLib";
import { compileContracts, getViemAccount } from "../../utils";
import { upgradeProxyImplementation } from "../utils";
import { setCreValidatorLibVars } from "./setCreValidatorLibVars";

async function deployCreValidatorLibTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployConceroCreValidatorLib(hre);
	}

	if (taskArgs.proxy) {
		const { abi } = await import(
			"../../artifacts/contracts/validators/CreValidatorLib/CreValidatorLib.sol/CreValidatorLib.json"
		);
		const privateKeyAccount = getViemAccount("testnet", "deployer");
		const initializerCallData = encodeFunctionData({
			abi,
			functionName: "initialize",
			args: [privateKeyAccount.address],
		});

		await deployProxyAdmin(hre, ProxyEnum.creValidatorLibProxy);
		await deployTransparentProxy(hre, ProxyEnum.creValidatorLibProxy, initializerCallData);
	}

	if (taskArgs.implementation && !taskArgs.proxy) {
		await upgradeProxyImplementation(hre, ProxyEnum.creValidatorLibProxy, false);
	}

	if (taskArgs.vars) {
		await setCreValidatorLibVars(hre.network.name);
	}
}

task("deploy-cre-validator-lib", "")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.addFlag("vars", "")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployCreValidatorLibTask(taskArgs, hre);
	});

export { deployCreValidatorLibTask };
