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

import { DomainError, ErrorCode, GlobalConfig } from "../helpers";
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
				requestId++;
				const isMedianAggregation = method === "eth_blockNumber";
				const body = {
					jsonrpc: "2.0",
					id: requestId,
					method,
					params,
				};
				const httpClient = new cre.capabilities.HTTPClient();

				let response: any;

				if (isMedianAggregation) {
					httpClient
						.sendRequest(
							runtime,
							fetcher.build(runtime, { url, method: "POST", body, headers }, res =>
								BigInt(JSON.parse(res as string).result),
							),
							consensusMedianAggregation(),
						)()
						.result();

					response = fetcher.getResponse();
				} else {
					httpClient
						.sendRequest(
							runtime,
							fetcher.build(runtime, { url, method: "POST", body, headers }),
							consensusIdenticalAggregation(),
						)()
						.result();

					response = fetcher.getResponse();
				}

				if (!response.result) {
					throw new DomainError(ErrorCode.RPC_REQUEST_FAILED, response);
				}

				return response.result;
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
				this.shuffle(chain.rpcUrls).map(i => PublicClient.createHttpTransport(runtime, i)),
			),
		});
		chainSelectorToClient[chainSelector] = client;

		return client;
	}

	static shuffle(arr: any[]) {
		for (let i = arr.length - 1; i > 0; i--) {
			const j = Math.floor(Math.random() * (i + 1));
			[arr[i], arr[j]] = [arr[j], arr[i]];
		}
		return arr;
	}
}
