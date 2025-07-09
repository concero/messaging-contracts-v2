import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks, ProxyEnum } from "../../constants";
import { setGasFeeConfig } from "../utils/setGasFeeConfig";

async function setVerifierVariables(hre: HardhatRuntimeEnvironment) {
	const { live, name } = hre.network;
	const network = conceroNetworks[name];

	await setGasFeeConfig(network, ProxyEnum.verifierProxy);
}

export { setVerifierVariables };
