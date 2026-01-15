import { Runtime } from "@chainlink/cre-sdk";

import { GlobalConfig } from "../helpers";
import { IValidation } from "./buildValidation";

export const sendReportsToRelayer = (
	runtime: Runtime<GlobalConfig>,
	validation: IValidation,
): void => {
	console.log(JSON.stringify(validation));
	// new cre.capabilities.HTTPClient()
	// 	.sendRequest(
	// 		runtime,
	// 		fetcher.build(runtime, {
	// 			url: runtime.config.relayerCallbackUrl,
	// 			method: "POST",
	// 			body: validation,
	// 			headers,
	// 		}),
	// 		consensusIdenticalAggregation<any>(),
	// 	)()
	// 	.result();
};
