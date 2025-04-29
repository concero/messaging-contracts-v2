import { task } from "hardhat/config";

import { deployConceroClientExample } from "../deploy";

task("deploy-example-client", "").setAction(async (taskArgs, hre) => {
	await deployConceroClientExample(hre);
});

export default {};
