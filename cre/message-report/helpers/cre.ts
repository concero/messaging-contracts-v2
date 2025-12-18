import { HTTPSendRequester, Runtime, ok } from "@chainlink/cre-sdk";

import { GlobalConfig } from "./types";

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

			const rawRequestBody =
				typeof options.body === "string" ? options.body : JSON.stringify(options.body);
			const bodyRequestBytes = options.body ? new TextEncoder().encode(rawRequestBody) : null;

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

			const dTime = Date.now() - start;
			if (!ok(response)) {
				runtime.log(`buildFetcher Failed ${JSON.stringify(response)} in ${dTime}ms`);
				throw new Error(`HTTP request failed with status: ${response.statusCode} `);
			} else {
				runtime.log(`buildFetcher Succeeded ${JSON.stringify(response)} in ${dTime}ms`);
			}

			const decodedResponse = new TextDecoder().decode(response.body);

			return mapper ? mapper(decodedResponse) : (decodedResponse as ResponseBody);
		};
	}
}
