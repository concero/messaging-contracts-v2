import { Runtime, consensusIdenticalAggregation, cre } from "@chainlink/cre-sdk";

import { GlobalConfig } from "../helpers";
import { headers } from "../helpers/constants";
import { fetcher } from "../helpers/fetcher";
import { type buildResponseFromBatches } from "./buildResponseFromBatches";

export const sendReportsToRelayer = (
	runtime: Runtime<GlobalConfig>,
	response: ReturnType<typeof buildResponseFromBatches>,
): void => {
	runtime.log(
		"Response: " +
			(Object.keys(response).length > 0
				? Object.keys(response)
						.map(messageId => `${messageId}:${response[messageId].signs.length}`)
						.join(", ")
				: "empty"),
	);

	new cre.capabilities.HTTPClient()
		.sendRequest(
			runtime,
			fetcher.build(runtime, {
				url: runtime.getSecret({ id: "RELAYER_CALLBACK_URL" }).result().value,
				method: "POST",
				body: response,
				headers,
			}),
			consensusIdenticalAggregation(),
		)()
		.result();
};
