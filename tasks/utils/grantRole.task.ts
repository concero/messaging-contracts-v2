import { task } from "hardhat/config";

import { HardhatRuntimeEnvironment } from "hardhat/types";

import { getFallbackClients } from "../../utils";

export async function grantRole(hre: HardhatRuntimeEnvironment, taskArgs: any) {
	const account = taskArgs.account;
	const role = taskArgs.role;
	const contract = taskArgs.contract;
	const { abi: accessControlAbi } = hre.artifacts.readArtifactSync("AccessControlUpgradeable");

	const { walletClient, publicClient } = getFallbackClients(hre.network);

	const hasRole = await publicClient.readContract({
		address: contract,
		abi: accessControlAbi,
		functionName: "hasRole",
		args: [],
	});
}

task("grant-role", "")
	.addParam("role", "")
	.addParam("account", "")
	.addParam("contract", "")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await grantRole(hre, taskArgs);
	});
