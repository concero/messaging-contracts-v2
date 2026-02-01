import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
	conceroNetworks,
	getFallbackClients,
	getTrezorAddress,
	getTrezorDeployEnabled,
	log,
} from "@concero/contract-utils";
import { Address, formatUnits } from "viem";

task("deployer-balance", "").setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
	const isTrezorDeploy = getTrezorDeployEnabled();

	let address: Address;

	if (isTrezorDeploy) {
		address = await getTrezorAddress();
	} else {
		const [deployer] = await hre.ethers.getSigners();
		address = deployer.address as Address;
	}

	const { publicClient } = getFallbackClients(conceroNetworks[hre.network.name]);

	log(
		`Balance: ${formatUnits(await publicClient.getBalance({ address }), 18)}`,
		"balance",
		hre.network.name,
	);
});

export default {};
