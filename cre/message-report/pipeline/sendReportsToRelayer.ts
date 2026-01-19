import { Runtime, consensusIdenticalAggregation, cre } from "@chainlink/cre-sdk";

import { GlobalConfig } from "../helpers";
import { headers } from "../helpers/constants";
import { fetcher } from "../helpers/fetcher";
import { IValidation } from "./buildValidation";

export const sendReportsToRelayer = (
	runtime: Runtime<GlobalConfig>,
	validation: IValidation,
): void => {
	new cre.capabilities.HTTPClient()
		.sendRequest(
			runtime,
			fetcher.build(runtime, {
				url: runtime.config.relayerCallbackUrl,
				method: "POST",
				body: validation,
				headers,
			}),
			consensusIdenticalAggregation<any>(),
		)()
		.result();
};
