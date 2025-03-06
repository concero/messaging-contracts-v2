import { configureDotEnv } from "./configureDotEnv";
import { formatGas, shorten } from "./formatting";
import { getEnvAddress, getEnvVar } from "./getEnvVar";
import {
	getEthersSignerAndProvider,
	getEthersV5FallbackSignerAndProvider,
	getEthersV6FallbackSignerAndProvider,
	getEthersV6SignerAndProvider,
} from "./getEthersSignerAndProvider";
import { getGasParameters } from "./getGasParameters";
import getHashSum from "./getHashSum";
import { getClients, getFallbackClients, getTestClient } from "./getViemClients";
import { getWallet } from "./getWallet";
import { err, log, warn } from "./log";
import { updateEnvAddress, updateEnvVariable } from "./updateEnvVariable";

export {
	configureDotEnv,
	shorten,
	formatGas,
	getEnvVar,
	getEnvAddress,
	getEthersV5FallbackSignerAndProvider,
	getEthersSignerAndProvider,
	getEthersV6FallbackSignerAndProvider,
	getEthersV6SignerAndProvider,
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
};
