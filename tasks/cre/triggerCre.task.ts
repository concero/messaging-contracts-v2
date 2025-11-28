import { task } from "hardhat/config";

import { getEnvVar } from "../../utils";
import { createJWT } from "./createJwt";

const creUrl = "https://01.gateway.zone-a.cre.chain.link";
const workflowId = "0013d068e9a757b032bfeda27e4a898e2f86db58939f36467d4f3aa50b05e252";

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

// const c = { "messageId": "0x7c3d926037fd649729267301986eabcd3517c34dcb97c484656e93b16e9bec51", "srcChainSelector": 80002, "blockNumber": "29002698" }
