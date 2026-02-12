import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { generateGasLimitConfigs } from "../utils/generateGasLimitConfigs";

async function generateGasLimitConfigsTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	await generateGasLimitConfigs(hre);
}

// yarn hardhat generate-gas-limit-configs
task(
	"generate-gas-limit-configs",
	"Generate gas limit configurations for RelayerLib and CreValidatorLib based on viem gas estimates",
).setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
	await generateGasLimitConfigsTask(taskArgs, hre);
});

export { generateGasLimitConfigsTask };
