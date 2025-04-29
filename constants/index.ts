import { secrets } from "./clf/secrets";
import {
	CLF_DON_HOSTED_SECRETS_SLOT,
	CLF_MAINNET_TTL,
	CLF_SECRETS_ETHEREUM_EXPIRATION,
	CLF_SECRETS_TESTNET_EXPIRATION,
	CLF_TESTNET_TTL,
} from "./clf/secretsConfig";
import { simulationConfig } from "./clf/simulationConfig";
import { conceroNetworks } from "./conceroNetworks";
import {
	ProxyEnum,
	envPrefixes,
	getViemReceiptConfig,
	viemReceiptConfig,
	writeContractConfig,
} from "./deploymentVariables";
import { networkEnvKeys } from "./networkEnvKeys";
// import { liveNetworks } from "./liveNetworks";
import { urls } from "./rpcUrls";

export {
	secrets,
	CLF_DON_HOSTED_SECRETS_SLOT,
	CLF_MAINNET_TTL,
	CLF_SECRETS_ETHEREUM_EXPIRATION,
	CLF_SECRETS_TESTNET_EXPIRATION,
	CLF_TESTNET_TTL,
	simulationConfig,
	conceroNetworks,
	networkEnvKeys,
	viemReceiptConfig,
	writeContractConfig,
	ProxyEnum,
	envPrefixes,
	getViemReceiptConfig,
	urls,
	// liveNetworks,
};
