import { task } from "hardhat/config";

import { testnetNetworks } from "../../constants/conceroNetworks";
import { setSupportedChains } from "./setSupportedChains";

async function updateSupportedChains() {
	const promises = [];
	for (const chain of Object.values(testnetNetworks)) {
		promises.push(setSupportedChains(chain));
	}

	await Promise.all(promises);
}

task("update-supported-chains-for-all-routers", "").setAction(async () => {
	await updateSupportedChains();
});

export default {};
