import { HTTPSendRequester, Runtime, ok } from "@chainlink/cre-sdk";

import { GlobalConfig } from "./types";

export namespace CRE {
	export function buildFetcher<RequestBody = unknown>(
		runtime: Runtime<GlobalConfig>,
		options: {
			url: string;
			method: "GET" | "POST";
			body?: RequestBody;
			headers?: Record<string, string>;
		},
	): (sendRequester: HTTPSendRequester, config: GlobalConfig) => string {
		return (sendRequester: HTTPSendRequester, config: GlobalConfig): string => {
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

			if (!ok(response)) {
				throw new Error(`HTTP request failed with status: ${response.statusCode}`);
			}

			return new TextDecoder().decode(response.body);
		};
	}
}
