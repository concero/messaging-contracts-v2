import { configureDotEnv } from "./configureDotEnv";

import type { IDeployResult } from "@concero/contract-utils";
import {
	compileContracts,
	err,
	ethersSignerCallContract,
	genericDeploy,
	getClients,
	getEnvVar,
	getFallbackClients,
	getNetworkEnvKey,
	getTestClient,
	getTrezorDeployEnabled,
	getViemAccount,
	getWallet,
	log,
	warn,
} from "@concero/contract-utils";

import { getEnvAddress } from "./createEnvAddressGetter";
import { updateEnvAddress, updateEnvVariable } from "./createEnvUpdater";
import { getEnvFileName } from "./getEnvFileName";
import {
	getEthersSignerAndProvider,
	getEthersV5FallbackSignerAndProvider,
	getEthersV6FallbackSignerAndProvider,
	getEthersV6SignerAndProvider,
} from "./getEthersSignerAndProvider";
import { getGasParameters } from "./getGasParameters";
import { getHashSum } from "./getHashSum";

export {
	compileContracts,
	configureDotEnv,
	getEnvVar,
	getEnvAddress,
	getEthersV5FallbackSignerAndProvider,
	getEthersSignerAndProvider,
	getEthersV6FallbackSignerAndProvider,
	getEthersV6SignerAndProvider,
	getViemAccount,
	getHashSum,
	getClients,
	getFallbackClients,
	getTestClient,
	log,
	warn,
	err,
	updateEnvVariable,
	updateEnvAddress,
	getWallet,
	getGasParameters,
	getEnvFileName,
	getTrezorDeployEnabled,
	genericDeploy,
	getNetworkEnvKey,
	ethersSignerCallContract,
};

export type { IDeployResult };
