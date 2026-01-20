import { task } from "hardhat/config";

import { execSync } from "child_process";

import { testnetNetworks } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { getEnvVar, getNetworkEnvKey } from "../../utils";

task("deploy-concero-pause-to-all-chains", "").setAction(
	async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		for (const chain in testnetNetworks) {
			if (!getEnvVar(`CONCERO_PAUSE_${getNetworkEnvKey(chain)}`)) {
				execSync(`yarn hardhat deploy --tags PauseDummy --network ${chain}`, {
					stdio: "inherit",
				});
			}
		}
	},
);

export default {};
