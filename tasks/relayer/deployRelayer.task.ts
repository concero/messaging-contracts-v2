import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, encodeFunctionData } from "viem";

import { ADMIN_ROLE, ProxyEnum } from "../../constants";
import { deployTransparentProxy } from "../../deploy";
import { deployRelayerLib } from "../../deploy/RelayerLib";
import { compileContracts, getEnvAddress } from "../../utils";
import { upgradeProxyImplementation } from "../utils";
import { grantRole } from "../utils/grantRole.task";
import { setRelayerLibVars } from "./setRelayerLibVars";
import { getTrezorAddress, getTrezorDeployEnabled, log } from "@concero/contract-utils";

async function deployRelayerLibTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	compileContracts({ quiet: true });

	if (taskArgs.implementation) {
		await deployRelayerLib(hre);
	}

	if (taskArgs.proxy) {
		const { abi } = hre.artifacts.readArtifactSync("RelayerLib");

		// TODO: refactor it
		const [ethersSigner] = await hre.ethers.getSigners();

		const initialAdmin = getTrezorDeployEnabled()
			? await getTrezorAddress()
			: (ethersSigner.address as Address);

		log(`Initial admin for relayer lib: ${initialAdmin}`, hre.network.name);

		const initializerCallData = encodeFunctionData({
			abi,
			functionName: "initialize",
			args: [initialAdmin],
		});

		await deployTransparentProxy(hre, ProxyEnum.relayerLibProxy, initializerCallData);
	}

	if (taskArgs.implementation && !taskArgs.proxy) {
		await upgradeProxyImplementation(hre, ProxyEnum.relayerLibProxy, false);
	}

	if (taskArgs.vars) {
		await setRelayerLibVars(hre.network.name);
	}

	if (taskArgs.admin) {
		const [relayerLibProxy] = getEnvAddress(ProxyEnum.relayerLibProxy, hre.network.name);

		await grantRole(hre, {
			role: ADMIN_ROLE,
			account: taskArgs.admin,
			contract: relayerLibProxy,
		});
	}
}

task("deploy-relayer-lib", "")
	.addFlag("proxy", "Deploy proxy")
	.addFlag("implementation", "Deploy implementation")
	.addFlag("vars", "Set contract variables")
	.addOptionalParam("admin", "Second admin address")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await deployRelayerLibTask(taskArgs, hre);
	});

export { deployRelayerLibTask };
