import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, encodeFunctionData } from "viem";

import { ADMIN_ROLE, ProxyEnum } from "../../constants";
import { deployTransparentProxy } from "../../deploy";
import deployConceroCreValidatorLib from "../../deploy/ConceroCreValidatorLib";
import { compileContracts, getEnvAddress } from "../../utils";
import { upgradeProxyImplementation } from "../utils";
import { grantRole } from "../utils/grantRole.task";
import { setCreValidatorLibVars } from "./setCreValidatorLibVars";

async function deployCreValidatorLibTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployConceroCreValidatorLib(hre);
	}

	if (taskArgs.proxy) {
		const { abi } = hre.artifacts.readArtifactSync("CreValidatorLib");
		const [ethersSigner] = await hre.ethers.getSigners();

		const initializerCallData = encodeFunctionData({
			abi,
			functionName: "initialize",
			args: [ethersSigner.address as Address],
		});

		await deployTransparentProxy(hre, ProxyEnum.creValidatorLibProxy, initializerCallData);
	}

	if (taskArgs.implementation && !taskArgs.proxy) {
		await upgradeProxyImplementation(hre, ProxyEnum.creValidatorLibProxy, false);
	}

	if (taskArgs.vars) {
		await setCreValidatorLibVars(hre.network.name);
	}

	if (taskArgs.admin) {
		const [creValidatorLibProxy] = getEnvAddress(
			ProxyEnum.creValidatorLibProxy,
			hre.network.name,
		);

		await grantRole(hre, {
			role: ADMIN_ROLE,
			account: taskArgs.admin,
			contract: creValidatorLibProxy,
		});
	}
}

task("deploy-cre-validator-lib", "")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.addFlag("vars", "")
	.addOptionalParam("admin", "Second admin address")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployCreValidatorLibTask(taskArgs, hre);
	});

export { deployCreValidatorLibTask };
