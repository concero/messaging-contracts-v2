import { HTTPSendRequester, Runtime } from "@chainlink/cre-sdk";

import { CRE, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { headers } from "../helpers/constants";
import { Hex, sha256 } from "viem";

export enum DeploymentType {
	Router = "router",
	ValidatorLib = "validatorLib",
	RelayerLib = "relayerLib",
}
export type DeploymentAddress = `0x${string}`;

export type ChainSelector = number;

export type Chain = {
	id: string;
	chainSelector: ChainSelector;
	name: string;
	isTestnet: boolean;
	finalityTagEnabled?: boolean;
	finalityConfirmations?: number;
	isFinalitySupported?: boolean;
	getLogsBlockDepth?: number;
	minBlockConfirmations: number;
	rpcUrls: string[];
	blockExplorers: {
		name: string;
		url: string;
		apiUrl: string;
	}[];
	nativeCurrency: {
		name: string;
		symbol: string;
		decimals: number;
	};
	deployments: Partial<Record<DeploymentType, DeploymentAddress>>;
};

let chains: Record<Chain["chainSelector"], Chain> = {};

export class ChainsManager {
	static enrichOptions(
		runtime: Runtime<GlobalConfig>,
		sendRequester: HTTPSendRequester,
		chainsConfigHash: Hex,
	) {
		chains = CRE.sendHttpRequestSync(sendRequester, {
			url: runtime.config.chainsConfigUrl,
			method: "GET",
			headers,
		});

		const currentChainsHashSum = sha256(Buffer.from(JSON.stringify(chains))).toLowerCase();
		if (chainsConfigHash.toLowerCase() !== currentChainsHashSum) {
			runtime.log(
				`Invalid chains hash. Current: ${chainsConfigHash.toLowerCase()}. Expected: ${currentChainsHashSum}`,
			);
			throw new DomainError(ErrorCode.INVALID_HASH_SUM, "Chains hash sum invalid");
		}
	}

	static getOptionsBySelector(chainSelector: Chain["chainSelector"]): Chain {
		const chainOption = chains[chainSelector];

		if (!chainOption) {
			throw new DomainError(ErrorCode.NO_CHAIN_DATA, "Chain not found");
		}

		return chainOption;
	}
}
