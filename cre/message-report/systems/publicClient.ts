import { Runtime, consensusIdenticalAggregation, cre } from "@chainlink/cre-sdk";
import {
	Transport,
	type PublicClient as ViemPublicClient,
	createPublicClient,
	custom,
	fallback,
} from "viem";

import { CRE, DomainError, ErrorCode, GlobalConfig, Utility } from "../helpers";
import { ChainsManager } from "./chainsManager";

const chainSelectorToClient: Record<number, ViemPublicClient> = {};

const LOG_TAG = "PublicClient";

export class PublicClient {
	static createHttpTransport(runtime: Runtime<GlobalConfig>, url: string): Transport {
		return custom({
			async request({ method, params }) {
				const body = [
					{
						jsonrpc: "2.0",
						id: Date.now(),
						method,
						params,
					},
				];
				const fetcher = CRE.buildFetcher(runtime, {
					url,
					method: "POST",
					body,
					headers: {
						"Content-Type": "application/json",
					},
				});

				const httpClient = new cre.capabilities.HTTPClient();
				const rawResponseBody = httpClient
					.sendRequest(runtime, fetcher, consensusIdenticalAggregation())(runtime.config)
					.result();

				const responseBody: Record<number, Record<string, unknown>>[] =
					Utility.safeJSONParse(rawResponseBody);
				const result: any = (
					Object.values(responseBody || {}) as Record<string, unknown>[]
				)?.map(i => i?.result)?.[0];

				return result;
			},
		});
	}

	static create(runtime: Runtime<GlobalConfig>, chainSelector: number): ViemPublicClient {
		if (chainSelectorToClient[chainSelector]) {
			return chainSelectorToClient[chainSelector];
		}

		const chain = ChainsManager.getOptionsBySelector(chainSelector);
		runtime.log(`${LOG_TAG}|create Got chain: ${JSON.stringify(chain)}`);
		if (!chain) {
			throw new DomainError(ErrorCode.NO_CHAIN_DATA, "Chain not found");
		}
		if (!chain.rpcUrls.length) {
			throw new DomainError(ErrorCode.NO_CHAIN_DATA, "Chain RPCs not found");
		}

		const client = createPublicClient({
			chain: {
				id: Number(chain.id),
				name: chain.name,
				nativeCurrency: chain.nativeCurrency,
				rpcUrls: {
					default: {
						http: chain.rpcUrls,
					},
				},
			},
			transport: fallback(
				chain.rpcUrls.map(i => PublicClient.createHttpTransport(runtime, i)),
			),
		});
		chainSelectorToClient[chainSelector] = client;

		return client;
	}
}
