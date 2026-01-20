import { Runtime } from "@chainlink/cre-sdk";

import { GlobalConfig } from "../helpers";

export function generateReport(runtime: Runtime<GlobalConfig>, data: string) {
	return runtime
		.report({
			encoderName: "evm",
			encodedPayload: Buffer.from(new TextEncoder().encode(data)).toString("base64"),
			signingAlgo: "ecdsa",
			hashingAlgo: "keccak256",
		})
		.result()
		.x_generatedCodeOnly_unwrap();
}
