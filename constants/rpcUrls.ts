import { mainnetChains, testnetChains } from "@concero/rpcs";
import {
	mainnetNetworks as v2MainnetNetworks,
	testnetNetworks as v2TestnetNetworks,
} from "@concero/v2-networks";

import { getEnvVar } from "../utils";

export const urls: Record<string, string[]> = {
	hardhat: [getEnvVar("HARDHAT_RPC_URL")],
	localhost: [getEnvVar("LOCALHOST_RPC_URL")],
};

Object.keys(v2MainnetNetworks).forEach(networkName => {
	const chainId = v2MainnetNetworks[networkName].chainId.toString();
	if (mainnetChains[chainId]) {
		urls[networkName] = mainnetChains[chainId].urls;
	}
});

Object.keys(v2TestnetNetworks).forEach(networkName => {
	const chainId = v2TestnetNetworks[networkName].chainId.toString();
	if (testnetChains[chainId]) {
		urls[networkName] = testnetChains[chainId].urls;
	}
});
