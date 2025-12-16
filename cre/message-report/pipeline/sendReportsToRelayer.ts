import { Runtime, consensusIdenticalAggregation, cre } from "@chainlink/cre-sdk";

import { CRE, GlobalConfig } from "../helpers";
import { type buildResponseFromBatches } from "./buildResponseFromBatches";

export const sendReportsToRelayer = (
	runtime: Runtime<GlobalConfig>,
	response: ReturnType<typeof buildResponseFromBatches>,
): void => {
	//const relayerCallbackURL = runtime.getSecret({ id: "RELAYER_CALLBACK_URL" }).result().value;
	runtime.log(
		"Response: " +
			(Object.keys(response).length > 0
				? Object.keys(response)
						.map(messageId => `${messageId}:${response[messageId].signs.length}`)
						.join(", ")
				: "empty"),
	);

	const fetcher = CRE.buildFetcher(runtime, {
		url: "https://relayer.concero.io/api/v1/callback/cre",
		method: "POST",
		body: response,
		headers: {
			"Content-Type": "application/json",
		},
	});
	const httpClient = new cre.capabilities.HTTPClient();

	httpClient
		.sendRequest(runtime, fetcher, consensusIdenticalAggregation())(runtime.config)
		.result();
};
