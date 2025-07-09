import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks, ProxyEnum } from "../../constants";
import { setSupportedChains } from "./setSupportedChains";
import { setGasFeeConfig } from "../utils";

export async function setRouterVariables(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;
	const network = conceroNetworks[name];

	await setSupportedChains(network);
	await setGasFeeConfig(network, ProxyEnum.routerProxy);
}
