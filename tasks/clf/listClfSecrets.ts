import { SecretsManager } from "@chainlink/functions-toolkit";

import { gatewayUrls } from "../../constants/clf/gatewayUrls";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { getEnvVar, getEthersSignerAndProvider, getNetworkEnvKey, log } from "../../utils";

export async function listSecrets(
	chain: ConceroNetwork,
): Promise<{ [slotId: number]: { version: number; expiration: number } }> {
	const { signer } = getEthersSignerAndProvider(chain.url);
	const secretsManager = new SecretsManager({
		signer,
		functionsRouterAddress: getEnvVar(`CLF_ROUTER_${getNetworkEnvKey(chain.name)}`),
		donId: getEnvVar(`CLF_DONID_${getNetworkEnvKey(chain.name)}_ALIAS`),
	});

	await secretsManager.initialize();

	const { result } = await secretsManager.listDONHostedEncryptedSecrets(gatewayUrls[chain.type]);
	const allSecrets = {};

	result.nodeResponses.forEach(nodeResponse => {
		if (nodeResponse.rows) {
			nodeResponse.rows.forEach(row => {
				if (allSecrets[row.slot_id] && allSecrets[row.slot_id].version !== row.version)
					return log(
						`Node mismatch for slot_id. ${allSecrets[row.slot_id]} !== ${row.slot_id}!`,
						"listSecrets",
					);
				allSecrets[row.slot_id] = { version: row.version, expiration: row.expiration };
			});
		}
	});
	log(`DON secrets for ${chain.name}:`, "listSecrets");
	console.log(allSecrets);
	return allSecrets;
}
