import { execSync } from "child_process";

import { task } from "hardhat/config";

import { testnetNetworks } from "../../constants/conceroNetworks";
import { getEnvVar } from "../../utils";

task("deploy-concero-pause-to-all-chains", "").setAction(
	async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		for (const chain in testnetNetworks) {
			try {
				getEnvVar(`CONCERO_PAUSE_${getNetworkEnvKey(chain)}`);
			} catch (error) {
				if (!error.message.includes("Missing required environment variable"))
					throw new Error("unknown error");
				if (chain === undefined) throw new Error("chain not found");

				execSync(`yarn hardhat deploy --tags PauseDummy --network ${chain}`, {
					stdio: "inherit",
				});
			}
		}
	},
);

export default {};
