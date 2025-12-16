import { task } from "hardhat/config";

import { getEnvVar } from "../../utils";
import { createJWT } from "./createJwt";

const creUrl = "https://01.gateway.zone-a.cre.chain.link";
const workflowId = "0073929f2a9b980a15cdfa169ab56a1275aa2a6a28e9a457a74e62d1c5bdd27f";

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
							"0x48147a8e75ea1c6ce3aae570c4b1e0b5ae79aae561d161634807f91ee3c510eb",
						srcChainSelector: 80002,
						blockNumber: 29739120,
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

// {"batch": [ { "messageId": "0xed6b3e288128195b5d0ffd23833b74dce5f67e4a1a9cf9e0b8968c1bf9902ea6", "srcChainSelector": 80002, "blockNumber": "29635176" } ]}
