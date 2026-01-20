import { Runtime, hexToBase64 } from "@chainlink/cre-sdk";

import { GlobalConfig } from "../helpers";

export function generateReport(runtime: Runtime<GlobalConfig>, data: string) {
	return runtime
		.report({
			encoderName: "evm",
			encodedPayload: hexToBase64(data),
			signingAlgo: "ecdsa",
			hashingAlgo: "keccak256",
		})
		.result()
		.x_generatedCodeOnly_unwrap();
}
