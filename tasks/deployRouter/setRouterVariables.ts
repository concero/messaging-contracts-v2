import { HardhatRuntimeEnvironment } from "hardhat/types";

import { setMaxAllowedValidators } from "./setMaxAllowedValidators";

export async function setRouterVariables(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;

	await setMaxAllowedValidators(name);
}
