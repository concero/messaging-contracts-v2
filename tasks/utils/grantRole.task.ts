import { task } from "hardhat/config";

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Hash } from "viem";

import { conceroNetworks } from "../../constants";
import {
	ethersSignerCallContract,
	getFallbackClients,
	getTrezorDeployEnabled,
	log,
} from "../../utils";

// ADMIN role: 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42

export async function grantRole(hre: HardhatRuntimeEnvironment, taskArgs: any) {
	const account = taskArgs.account;
	const role = taskArgs.role;
	const contract = taskArgs.contract;
	const conceroNetwork = conceroNetworks[hre.network.name as keyof typeof conceroNetworks];
	const { abi: accessControlAbi } = hre.artifacts.readArtifactSync("AccessControlUpgradeable");
	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const functionArgs = [role, account];

	const hasRole = await publicClient.readContract({
		address: contract,
		abi: accessControlAbi,
		functionName: "hasRole",
		args: functionArgs,
	});

	if (hasRole === true) return;

	let hash: Hash;

	if (getTrezorDeployEnabled()) {
		hash = await ethersSignerCallContract(hre, contract, accessControlAbi, ...functionArgs);
	} else {
		hash = await walletClient.writeContract({
			address: contract,
			abi: accessControlAbi,
			functionName: "grantRole",
			args: functionArgs,
		});
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "grantRole", hre.network.name);
}

task("grant-role", "")
	.addParam("role", "")
	.addParam("account", "")
	.addParam("contract", "")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await grantRole(hre, taskArgs);
	});

export default {};
