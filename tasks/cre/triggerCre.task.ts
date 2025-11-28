import { task } from "hardhat/config";

import { getEnvVar } from "../../utils";
import { createJWT } from "./createJwt";

const creUrl = "https://01.gateway.zone-a.cre.chain.link";
const workflowId = "0031b4ce665d6a9e673ea26bfabb07cc2bfe86e1f8cdbf0a2e17482100b0d0d0";

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
							"0x361850ddbced44d2c34178636e0bb1290024a0979a7ab593fd5c4e99f2a9d616",
						srcChainSelector: 80002,
						blockNumber: 29634343,
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
