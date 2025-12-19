import { ConsensusAggregationByFields, Runtime, cre, identical, ignore } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { CRE, DomainError, ErrorCode, GlobalConfig } from "../helpers";

export enum DeploymentType {
	Router = "router",
	ValidatorLib = "validatorLib",
	RelayerLib = "relayerLib",
}
export type DeploymentAddress = `0x${string}`;

export type Chain = {
	id: string;
	chainSelector: number;
	name: string;
	isTestnet: boolean;
	finalityTagEnabled: boolean;
	finalityConfirmations: number;
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
let currentChainsHashSum: string = "";

export class ChainsManager {
	static enrichOptions(runtime: Runtime<GlobalConfig>) {
		const fetcher = CRE.buildFetcher(
			runtime,
			{
				url: "https://raw.githubusercontent.com/concero/concero-networks/refs/heads/master/output/chains.minified.json",
				method: "GET",
				headers: {
					"Content-Type": "application/json",
				},
			},
			decodedResponse => {
				return { result: decodedResponse, hash: sha256(Buffer.from(decodedResponse)) };
			},
		);
		const httpClient = new cre.capabilities.HTTPClient();

		const rawResponse = httpClient
			.sendRequest(
				runtime,
				fetcher,
				ConsensusAggregationByFields({
					result: ignore,
					hash: identical,
				}),
			)(runtime.config)
			.result();

		chains = JSON.parse(rawResponse.result);

		console.log(JSON.stringify(chains[80002]), typeof chains);

		currentChainsHashSum = sha256(Buffer.from(rawResponse.result)).toLowerCase();
	}

	static validateOptions(runtime: Runtime<GlobalConfig>): void {
		const originalChainsChecksum = runtime
			.getSecret({ id: "CHAINS_CONFIG_HASHSUM" })
			.result().value;

		if (originalChainsChecksum !== currentChainsHashSum) {
			runtime.log(currentChainsHashSum);
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
