import { HTTPSendRequester, Runtime, ok } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { GlobalConfig } from "./types";

const LOG_TAG = "buildFetcher";

export namespace CRE {
	export interface IFetcherOptions {
		url: string;
		method: "GET" | "POST";
		body?: any;
		headers?: Record<string, string>;
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
			options: CRE.IFetcherOptions,
			mapper?: (decodedResponse: unknown) => unknown,
		): (sendRequester: HTTPSendRequester) => unknown {
			return (sendRequester: HTTPSendRequester) => {
				const start = Date.now();
				runtime.log(`${LOG_TAG} request started`);
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

				runtime.log(`${LOG_TAG} respond to request`);

				const dTime = Date.now() - start;
				if (!ok(res)) {
					runtime.log(`${LOG_TAG} request failed in ${dTime}ms ${JSON.stringify(res)}`);
					return null;
				} else {
					const decodedResponse = new TextDecoder().decode(res.body);

					runtime.log(
						`${LOG_TAG} request succeeded in ${dTime}ms ${JSON.stringify(decodedResponse)}`,
					);

					this.response = mapper ? mapper(decodedResponse) : (decodedResponse as string);

					return decodedResponse.length > this.MAX_RESPONSE_LENGTH
						? sha256(res.body)
						: this.response;
				}
			};
		}
	}
}
