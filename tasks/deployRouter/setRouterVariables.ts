import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../../constants";
import { setSupportedChains } from "./setSupportedChains";
import { setGasFeeConfig } from "./setGasFeeConfig";

export async function setRouterVariables(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;
	const network = conceroNetworks[name];

	await setSupportedChains(network);
	await setGasFeeConfig(network);
}
