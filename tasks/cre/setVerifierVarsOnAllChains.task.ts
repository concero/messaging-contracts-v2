import { task } from "hardhat/config";
import { mainnetChains, testnetChains } from "@concero/rpcs";
import { getEnvVar } from "@concero/contract-utils";
import { getNetworkEnvKey } from "../../utils";
import { setCreValidatorLibVars } from "./setCreValidatorLibVars";

task("set-verifier-vars-on-all-chains", "")
	.addFlag("testnet")
	.setAction(async taskArgs => {
		const chains = taskArgs.testnet ? testnetChains : mainnetChains;

		for (const chain in chains) {
			const creValidatorLib = getEnvVar(
				`CONCERO_CRE_VALIDATOR_LIB_PROXY_${getNetworkEnvKey(chain)}`,
			);
			if (!creValidatorLib) continue;

			try {
				await setCreValidatorLibVars(chain);
			} catch (e) {
				console.error(e);
			}
		}
	});

export default {};
