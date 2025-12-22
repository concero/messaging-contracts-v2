import { type HTTPPayload, Runner, type Runtime, cre } from "@chainlink/cre-sdk";

import { GlobalConfig } from "./helpers";
import { pipeline } from "./pipeline";

const onHttpTrigger = async (runtime: Runtime<GlobalConfig>, payload: HTTPPayload) => {
	return pipeline(runtime, payload);
};

const initWorkflow = (config: GlobalConfig) => {
	const httpTrigger = new cre.capabilities.HTTPCapability().trigger({
		authorizedKeys: [{ type: "KEY_TYPE_ECDSA_EVM", publicKey: config.authorizedPublicKey }],
	});

	return [cre.handler(httpTrigger, onHttpTrigger)];
};

export async function main() {
	const runner = await Runner.newRunner<GlobalConfig>();

	await runner.run(initWorkflow);
}

main();
