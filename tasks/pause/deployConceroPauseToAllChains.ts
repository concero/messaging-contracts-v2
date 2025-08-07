import { execSync } from "child_process";

import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { getNetworkEnvKey } from "@concero/contract-utils";

import { testnetNetworks } from "../../constants/conceroNetworks";
import { getEnvVar } from "../../utils";

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
