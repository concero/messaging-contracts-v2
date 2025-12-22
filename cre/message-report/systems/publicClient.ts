import {
	Runtime,
	consensusIdenticalAggregation,
	consensusMedianAggregation,
	cre,
} from "@chainlink/cre-sdk";
import {
	Transport,
	type PublicClient as ViemPublicClient,
	createPublicClient,
	custom,
	fallback,
} from "viem";

import { DomainError, ErrorCode, GlobalConfig, Utility } from "../helpers";
import { headers } from "../helpers/constants";
import { fetcher } from "../helpers/fetcher";
import { ChainsManager } from "./chainsManager";

const chainSelectorToClient: Record<number, ViemPublicClient> = {};

const LOG_TAG = "PublicClient";

let requestId: number = 0;

export class PublicClient {
	static createHttpTransport(runtime: Runtime<GlobalConfig>, url: string): Transport {
		return custom({
			async request({ method, params }) {
				try {
					requestId++;
					const isMedianAggregation = method === "eth_blockNumber";
					const body = {
						jsonrpc: "2.0",
						id: requestId,
						method,
						params,
					};
					const httpClient = new cre.capabilities.HTTPClient();

					if (isMedianAggregation) {
						httpClient
							.sendRequest(
								runtime,
								fetcher.build(
									runtime,
									{ url, method: "POST", body, headers },
									decodedResponse => {
										const responseBody: Record<string, unknown> =
											Utility.safeJSONParse(decodedResponse as string);
										return BigInt(responseBody.result as string);
									},
								),
								consensusMedianAggregation(),
							)()
							.result();

						return fetcher.getResponse();
					} else {
						httpClient
							.sendRequest(
								runtime,
								fetcher.build(
									runtime,
									{ url, method: "POST", body, headers },
									decodedResponse => {
										const responseBody: Record<string, unknown> =
											Utility.safeJSONParse(decodedResponse as string);
										return responseBody.result as string;
									},
								),
								consensusIdenticalAggregation(),
							)()
							.result();

						return fetcher.getResponse();
					}
				} catch (e) {
					runtime.log(`${LOG_TAG} unhandled error: ${e}`);
					return null;
				}
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
				rpcUrls: { default: { http: chain.rpcUrls } },
			},
			transport: fallback(
				chain.rpcUrls.map(i => PublicClient.createHttpTransport(runtime, i)),
			),
		});
		chainSelectorToClient[chainSelector] = client;

		return client;
	}
}
