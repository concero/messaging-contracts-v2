import { SecretsManager } from "@chainlink/functions-toolkit";
import { getEnvVar, getEthersSignerAndProvider } from "../../utils";
import log from "../../utils/log";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { networkEnvKeys } from "../../constants";
import { clfGatewayUrls } from "../../constants/clfGatewayUrls";

export async function listSecrets(
    chain: ConceroNetwork,
): Promise<{ [slotId: number]: { version: number; expiration: number } }> {
    const { signer } = getEthersSignerAndProvider(chain.url);
    const secretsManager = new SecretsManager({
        signer,
        functionsRouterAddress: getEnvVar(`CLF_ROUTER_${networkEnvKeys[chain.name]}`),
        donId: getEnvVar(`CLF_DONID_${networkEnvKeys[chain.name]}_ALIAS`),
    });

    await secretsManager.initialize();

    const { result } = await secretsManager.listDONHostedEncryptedSecrets(clfGatewayUrls[chain.type]);
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
