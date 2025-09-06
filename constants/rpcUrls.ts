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
	if (mainnetChains[networkName]) {
		urls[networkName] = mainnetChains[networkName].urls;
	}
});

Object.keys(v2TestnetNetworks).forEach(networkName => {
	if (testnetChains[networkName]) {
		urls[networkName] = testnetChains[networkName].rpcUrls;
	}
});
