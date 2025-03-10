import { task } from "hardhat/config";

import { deployConceroClientExample } from "../deploy";

/**
 * Sends a Concero message using the ConceroClientExample contract
 */
task("deploy-example-client", "").setAction(async (taskArgs, hre) => {
	await deployConceroClientExample(hre);
});

export default {};
