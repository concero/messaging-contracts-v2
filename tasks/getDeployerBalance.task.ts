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

export async function getDeployerBalance(hre: HardhatRuntimeEnvironment): Promise<bigint> {
	const isTrezorDeploy = getTrezorDeployEnabled();

	let address: Address;

	if (isTrezorDeploy) {
		address = await getTrezorAddress();
	} else {
		const [deployer] = await hre.ethers.getSigners();
		address = deployer.address as Address;
	}

	const { publicClient } = getFallbackClients(conceroNetworks[hre.network.name]);

	return await publicClient.getBalance({ address });
}

task("deployer-balance", "").setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
	log(`Balance: ${formatUnits(await getDeployerBalance(hre), 18)}`, "balance", hre.network.name);
});

export default {};
