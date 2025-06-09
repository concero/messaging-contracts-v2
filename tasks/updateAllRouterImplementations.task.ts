import { execSync } from "child_process";

import { task } from "hardhat/config";

import { conceroNetworks } from "../constants";

task("update-all-router-implementations").setAction(async (taskArgs, hre) => {
	for (const network in conceroNetworks) {
		try {
			execSync(`yarn hardhat deploy-router --implementation --network ${network}`, {
				encoding: "utf8",
				stdio: "inherit",
			});
		} catch (error) {
			console.error(`Command failed for ${network}:`, error.stderr || error.message);
		}
	}
});

export default {};
