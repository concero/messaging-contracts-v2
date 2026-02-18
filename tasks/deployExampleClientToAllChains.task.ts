import { task } from "hardhat/config";
import type { HardhatRuntimeEnvironment } from "hardhat/types";
import { ChainRpcData, mainnetChains, testnetChains } from "@concero/rpcs";
import { execSync } from "child_process";
import { getEnvVar, getNetworkEnvKey } from "@concero/contract-utils";

task("deploy-example-client-to-all-chains", "").setAction(
	async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		let chains: Record<string, ChainRpcData>;
		if (taskArgs.isTestnet) {
			chains = testnetChains;
		} else {
			chains = mainnetChains;
		}

		for (const chain in chains) {
			try {
				if (!getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(chain)}`)) continue;
				if (getEnvVar(`CONCERO_CLIENT_EXAMPLE_${getNetworkEnvKey(chain)}`)) continue;

				execSync(`yarn hardhat deploy-example-client --network ${chain}`, {
					encoding: "utf8",
					stdio: "inherit",
				});
			} catch (error) {
				console.error(`Command failed for ${chain}:`, error.stderr || error.message);
			}
		}
	},
);

export default {};
