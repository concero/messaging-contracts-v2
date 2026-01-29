import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../../constants";
import { setVerifierGasFeeConfig } from "../utils";

export async function setVerifierVariables(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;
	const network = conceroNetworks[name];

	await setVerifierGasFeeConfig(network);
}
