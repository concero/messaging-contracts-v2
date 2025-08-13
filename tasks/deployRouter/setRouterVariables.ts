import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../../constants";
import { setRouterGasFeeConfig } from "../utils";
import { setSupportedChains } from "./setSupportedChains";

export async function setRouterVariables(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;
	const network = conceroNetworks[name];

	await setSupportedChains(network);
	await setRouterGasFeeConfig(network);
}
