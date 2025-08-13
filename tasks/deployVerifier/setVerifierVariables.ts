import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { ProxyEnum, conceroNetworks } from "../../constants";
import { getEnvAddress } from "../../utils/getEnvVar";
import { setVerifierGasFeeConfig } from "../utils";

export async function setVerifierVariables(hre: HardhatRuntimeEnvironment) {
	const { name } = hre.network;
	const network = conceroNetworks[name];

	// Get the verifier contract address
	const [contractAddress] = getEnvAddress(ProxyEnum.verifierProxy, network.name);

	await setVerifierGasFeeConfig(network, contractAddress);
}
