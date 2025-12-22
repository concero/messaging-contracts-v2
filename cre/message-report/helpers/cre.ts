import { HTTPSendRequester, Runtime } from "@chainlink/cre-sdk";
import { sha256 } from "viem";

import { GlobalConfig } from "./types";

const LOG_TAG = "BUILD_FETCHER";

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
