import { HTTPSendRequester, Runtime } from "@chainlink/cre-sdk";
import {
	Transport,
	type PublicClient as ViemPublicClient,
	createPublicClient,
	custom,
	fallback,
} from "viem";

import { CRE, DomainError, ErrorCode, GlobalConfig, Utility } from "../helpers";
import { headers } from "../helpers/constants";
import { ChainsManager } from "./chainsManager";

import safeJSONStringify = Utility.safeJSONStringify;

const chainSelectorToClient: Record<number, ViemPublicClient> = {};
let requestId: number = 0;

const LOG_TAG = "PublicClient";

export class PublicClient {
	static createHttpTransport(sendRequester: HTTPSendRequester, url: string): Transport {
		return custom({
			async request({ method, params }) {
				requestId++;
				const body = { id: requestId, method, params, jsonrpc: "2.0" };
				const options = { method: "POST", url, headers, body: JSON.stringify(body) };

				return CRE.sendHttpRequestSync(sendRequester, options).result;
			},
		});
	}

	static create(
		runtime: Runtime<GlobalConfig>,
		sendRequester: HTTPSendRequester,
		chainSelector: number,
	): ViemPublicClient {
		if (chainSelectorToClient[chainSelector]) {
			return chainSelectorToClient[chainSelector];
		}

		const chain = ChainsManager.getOptionsBySelector(chainSelector);
		runtime.log(`${LOG_TAG}|create Got chain: ${safeJSONStringify(chain)}`);
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
				this.shuffle(chain.rpcUrls).map(i =>
					PublicClient.createHttpTransport(sendRequester, i),
				),
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
