import { Runtime, consensusIdenticalAggregation, cre } from "@chainlink/cre-sdk";
import { Address } from "viem";

import { CRE, DomainError, ErrorCode, GlobalConfig } from "../helpers";
import { ChainsManager } from "./chainsManager";

export const chainSelectorToDeployment: Record<number, Address> = {};

export class DeploymentsManager {
	static fetchDeployments = (runtime: Runtime<GlobalConfig>): string => {
		const fetcher = CRE.buildFetcher(runtime, {
			url: runtime.config.deploymentsUrl,
			method: "GET",
			headers: {
				"Content-Type": "text/plain",
			},
		});

		const httpClient = new cre.capabilities.HTTPClient();
		return httpClient
			.sendRequest(runtime, fetcher, consensusIdenticalAggregation())(runtime.config)
			.result();
	};
	static convertEnvNameToCamelCase(envName: string): string {
		return envName
			.split("_")
			.map((part, i) =>
				i === 0
					? part.toLowerCase()
					: part.charAt(0).toUpperCase() + part.slice(1).toLowerCase(),
			)
			.join("");
	}
	static upsertDeploymentsFromEnv(envText: string): void {
		const lines = envText.split("\n");

		for (const line of lines) {
			if (!line || line.startsWith("#")) continue;
			const match = line.match(
				/^CONCERO_ROUTER_PROXY_(?!ADMIN_)([^=\n]+)=(0x[a-fA-F0-9]{40})$/,
			);
			if (match) {
				const [, rawName, address] = match;
				const name = DeploymentsManager.convertEnvNameToCamelCase(rawName);
				const chainOptions = ChainsManager.findOptionsByName(name);
				if (chainOptions) {
					chainSelectorToDeployment[chainOptions.id] = address as Address;
				}
			}
		}
	}

	static enrichDeployments(runtime: Runtime<GlobalConfig>) {
		const envs = DeploymentsManager.fetchDeployments(runtime);
		DeploymentsManager.upsertDeploymentsFromEnv(envs);
	}

	static getDeploymentByChainSelector(chainSelector: number): Address {
		const found = chainSelectorToDeployment[chainSelector];

		if (!found) {
			throw new DomainError(ErrorCode.NO_CHAIN_DATA);
		}

		return found;
	}
}
