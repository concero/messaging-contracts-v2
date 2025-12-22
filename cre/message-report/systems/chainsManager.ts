import { Runtime, consensusIdenticalAggregation, cre } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { fetcher } from "../helpers/fetcher";

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
		const httpClient = new cre.capabilities.HTTPClient();

		httpClient
			.sendRequest(
				runtime,
				fetcher.build(
					runtime,
					{
						url: "https://raw.githubusercontent.com/concero/concero-networks/refs/heads/master/output/chains.minified.json",
						method: "GET",
						headers: { "Content-Type": "application/json" },
					},
					decodedResponse => decodedResponse,
				),
				consensusIdenticalAggregation(),
			)()
			.result();

		const rawChains = fetcher.getResponse();

		if (rawChains === null) {
			throw new DomainError(ErrorCode.FAILED_TO_FETCH_CHAINS_CONFIG);
		}

		chains = JSON.parse(rawChains);

		currentChainsHashSum = sha256(Buffer.from(rawChains)).toLowerCase();
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
