import { task } from "hardhat/config";

import { HardhatRuntimeEnvironment } from "hardhat/types";

import { extractDonSigners } from "../utils/extractDonSigners";

async function extractDonSignersTask(taskArgs: any, hre: HardhatRuntimeEnvironment) {
	await extractDonSigners(taskArgs.registry, taskArgs.start, taskArgs.limit, hre);
}

// yarn hardhat extract-don-signers --start 0 --limit 10
task("extract-don-signers", "Extract DON signers from Chainlink CapabilitiesRegistry")
	.addParam("registry", "Registry address", "0x76c9cf548b4179F8901cda1f8623568b58215E62")
	.addOptionalParam("start", "Starting index for getDONs", "0")
	.addOptionalParam("limit", "Limit for getDONs (max number of DONs to fetch)", "10")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		await extractDonSignersTask(taskArgs, hre);
	});

export { extractDonSignersTask };
