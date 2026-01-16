import { HTTPSendRequester, Runtime } from "@chainlink/cre-sdk";
import { SendRequester } from "@chainlink/cre-sdk/dist/generated-sdk/capabilities/networking/http/v1alpha/client_sdk_gen";
import type { Response } from "@chainlink/cre-sdk/dist/generated/capabilities/networking/http/v1alpha/client_pb";
import { sha256 } from "viem";

import { GlobalConfig } from "./types";

const LOG_TAG = "FETCHER";

export namespace CRE {
	export interface IRequestOptions {
		url: string;
		method: "GET" | "POST";
		body?: any;
		headers?: Record<string, string>;
	}

	export interface IHttpPromiseResult {
		ok: boolean;
		response: Response | Error;
	}

	export function parseCreRawHttpResponse(res: Response) {
		try {
			return JSON.parse(new TextDecoder().decode(res.body));
		} catch {
			return null;
		}
	}

	export function sendHttpRequestSync(sendRequester: HTTPSendRequester, params: IRequestOptions) {
		return parseCreRawHttpResponse(sendRequester.sendRequest(params).result());
	}

	export function buildSendRequestPromises(
		sendRequester: HTTPSendRequester,
		paramsArr: IRequestOptions[],
	) {
		return paramsArr.map(params => sendRequester.sendRequest(params));
	}

	export function fulfillSendRequestPromises(
		promises: ReturnType<SendRequester["sendRequest"]>[],
	): IHttpPromiseResult[] {
		return promises.map(promise => {
			try {
				return { ok: true, response: promise.result() };
			} catch (e) {
				return { ok: false, response: e as Error };
			}
		});
	}

	export class AsyncFetcher {
		private promises: ReturnType<SendRequester["sendRequest"]>[] = [];

		constructor(private readonly sendRequester: HTTPSendRequester) {}

		add(request: IRequestOptions) {
			this.promises.push(this.sendRequester.sendRequest(request));
		}

		batchAdd(requests: IRequestOptions[]) {
			requests.forEach(req => this.add(req));
		}

		wait() {
			const results = fulfillSendRequestPromises(this.promises);
			this.promises = [];
			return results;
		}
	}

	export class Fetcher {
		private response: any | null = null;
		private MAX_RESPONSE_LENGTH = 20_000;

		getResponse() {
			const res = this.response;
			this.response = null;
			return res;
		}

		build(
			runtime: Runtime<GlobalConfig>,
			options: CRE.IRequestOptions,
			consensusDecoder?: (decodedResponse: unknown) => unknown,
		): (sendRequester: HTTPSendRequester) => unknown {
			return (sendRequester: HTTPSendRequester) => {
				const start = Date.now();

				const rawRequestBody =
					typeof options.body === "string"
						? options.body
						: JSON.stringify(options?.body || {});
				const bodyRequestBytes = options?.body
					? new TextEncoder().encode(rawRequestBody)
					: null;

				const res = sendRequester
					.sendRequest({
						url: options.url,
						method: options.method,
						...(bodyRequestBytes && {
							body: Buffer.from(bodyRequestBytes).toString("base64"),
						}),
						...(options.headers && { headers: options.headers }),
					})
					.result();

				this.response = res;

				const dTime = Date.now() - start;
				const decodedResponse = new TextDecoder().decode(res.body);

				runtime.log(`${LOG_TAG} request fulfilled in ${dTime}ms ${decodedResponse}`);

				this.response = JSON.parse(decodedResponse);

				return decodedResponse.length > this.MAX_RESPONSE_LENGTH
					? sha256(res.body)
					: consensusDecoder
						? consensusDecoder(decodedResponse)
						: (decodedResponse as string);
			};
		}
	}
}
