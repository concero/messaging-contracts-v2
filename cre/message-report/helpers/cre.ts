import { HTTPSendRequester, Runtime, ok } from "@chainlink/cre-sdk";

import { GlobalConfig } from "./types";

const LOG_TAG = "buildFetcher";
export namespace CRE {
	export function buildFetcher<RequestBody = unknown, ResponseBody = string>(
		runtime: Runtime<GlobalConfig>,
		options: {
			url: string;
			method: "GET" | "POST";
			body?: RequestBody;
			headers?: Record<string, string>;
		},
		mapper?: (decodedResponse: string) => ResponseBody,
	): (sendRequester: HTTPSendRequester, config: GlobalConfig) => ResponseBody {
		return (sendRequester: HTTPSendRequester, config: GlobalConfig): ResponseBody => {
			const start = Date.now();
			runtime.log(`${LOG_TAG} request started`);
			const rawRequestBody =
				typeof options.body === "string"
					? options.body
					: JSON.stringify(options?.body || {});
			const bodyRequestBytes = options?.body
				? new TextEncoder().encode(rawRequestBody)
				: null;

			const response = sendRequester
				.sendRequest({
					url: options.url,
					method: options.method,
					...(bodyRequestBytes && {
						body: Buffer.from(bodyRequestBytes).toString("base64"),
					}),
					...(options.headers && { headers: options.headers }),
				})
				.result();
			runtime.log(`${LOG_TAG} respond to request`);

			const dTime = Date.now() - start;
			if (!ok(response)) {
				runtime.log(`${LOG_TAG} request failed in ${dTime}ms ${JSON.stringify(response)}`);
				return null as ResponseBody;
			} else {
				const decodedResponse = new TextDecoder().decode(response.body);

				runtime.log(
					`${LOG_TAG} request succeeded in ${dTime}ms ${JSON.stringify(decodedResponse)}`,
				);

				return mapper ? mapper(decodedResponse) : (decodedResponse as ResponseBody);
			}
		};
	}
}
