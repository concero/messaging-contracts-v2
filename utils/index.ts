import { configureDotEnv } from "./configureDotEnv";

import { compileContracts } from "./compileContracts";
import { updateEnvAddress, updateEnvVariable } from "./createEnvUpdater";
import { formatGas, shorten } from "./formatting";
import { getEnvFileName } from "./getEnvFileName";
import { getEnvAddress, getEnvVar } from "./getEnvVar";
import {
	getEthersSignerAndProvider,
	getEthersV5FallbackSignerAndProvider,
	getEthersV6FallbackSignerAndProvider,
	getEthersV6SignerAndProvider,
} from "./getEthersSignerAndProvider";
import { getGasParameters } from "./getGasParameters";
import { getHashSum } from "./getHashSum";
import { getClients, getFallbackClients, getTestClient, getViemAccount } from "./getViemClients";
import { getWallet } from "./getWallet";
import { err, log, warn } from "./log";

export {
	compileContracts,
	configureDotEnv,
	shorten,
	formatGas,
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
};
