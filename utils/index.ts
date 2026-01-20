import { configureDotEnv } from "./configureDotEnv";

import {
	err,
	ethersSignerCallContract,
	genericDeploy,
	getEnvVar,
	getNetworkEnvKey,
	getTrezorDeployEnabled,
	getWallet,
	log,
	warn,
} from "@concero/contract-utils";

import { compileContracts } from "./compileContracts";
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
import { getClients, getFallbackClients, getTestClient, getViemAccount } from "./getViemClients";

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
