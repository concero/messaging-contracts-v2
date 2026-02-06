import { conceroNetworks } from "@concero/contract-utils";

import { secrets } from "./clf/secrets";
import {
	CLF_DON_HOSTED_SECRETS_SLOT,
	CLF_MAINNET_TTL,
	CLF_SECRETS_ETHEREUM_EXPIRATION,
	CLF_SECRETS_TESTNET_EXPIRATION,
	CLF_TESTNET_TTL,
} from "./clf/secretsConfig";
import { simulationConfig } from "./clf/simulationConfig";
import { DEPLOY_CONFIG_TESTNET } from "./deployConfigTestnet";
import {
	ADMIN_ROLE,
	ProxyEnum,
	getViemReceiptConfig,
	viemReceiptConfig,
	writeContractConfig,
} from "./deploymentVariables";
import { donRegistryAbi } from "./donRegistryAbi";
import { envPrefixes } from "./envPrefixes";
import { gasFeeConfig, gasFeeConfigVerifier, networkGasConfig } from "./gasConfig";
// import { liveNetworks } from "./liveNetworks";
import { urls } from "./rpcUrls";

export {
	ADMIN_ROLE,
	secrets,
	CLF_DON_HOSTED_SECRETS_SLOT,
	CLF_MAINNET_TTL,
	CLF_SECRETS_ETHEREUM_EXPIRATION,
	CLF_SECRETS_TESTNET_EXPIRATION,
	CLF_TESTNET_TTL,
	simulationConfig,
	conceroNetworks,
	mainnetNetworks,
	testnetNetworks,
	viemReceiptConfig,
	writeContractConfig,
	ProxyEnum,
	envPrefixes,
	getViemReceiptConfig,
	urls,
	gasFeeConfig,
	gasFeeConfigVerifier,
	networkGasConfig,
	// liveNetworks,
	DEPLOY_CONFIG_TESTNET,
	donRegistryAbi,
};
