import { task } from "hardhat/config";

import { getEnvVar } from "../../utils";
import { createJWT } from "./createJwt";

const creUrl = "https://01.gateway.zone-a.cre.chain.link";
const workflowId = "008030d6fc297b2f402098389276ac4c616f6635d6ab7777cb3455fc2d42c559";

task("trigger-cre", "").setAction(async taskArgs => {
	const body = {
		jsonrpc: "2.0",
		id: String(Date.now()),
		method: "workflows.execute",
		params: {
			input: {
				batch: [
					{
						messageId:
							"0xddbb3a30d56ea7bf809cb7f71940b01004e0025a0149e2ffe88f154c67d2e8c4",
						srcChainSelector: 80002,
						blockNumber: 29546068,
					},
				],
			},
			workflow: {
				workflowID: workflowId,
			},
		},
	};

	const jwt = await createJWT(body, "0x" + getEnvVar("CRE_REQUESTER_PRIVATE_KEY"));

	const res = await fetch(creUrl, {
		method: "POST",
		headers: {
			"Content-Type": "application/json",
			Authorization: `Bearer ${jwt}`,
		},
		body: JSON.stringify(body),
	});

	if (!res.ok) {
		console.error("CRE error:", res.status, await res.text());
		throw new Error(`Request failed with status ${res.status}`);
	}

	const data = await res.json();
	console.log("CRE response:", data);
});

export default {};

// const c ={"batch": [ { "messageId": "0xddbb3a30d56ea7bf809cb7f71940b01004e0025a0149e2ffe88f154c67d2e8c4", "srcChainSelector": 80002, "blockNumber": "29546068" } ]}
