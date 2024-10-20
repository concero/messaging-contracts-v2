import { SecretsManager } from "@chainlink/functions-toolkit";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { getEthersSignerAndProvider } from "../../utils/getEthersSignerAndProvider";
import log from "../../utils/log";

export async function listSecrets(
    chain: ConceroNetwork,
): Promise<{ [slotId: number]: { version: number; expiration: number } }> {
    const { signer } = getEthersSignerAndProvider(chain.url);
    const { functionsRouter, functionsDonIdAlias, functionsGatewayUrls } = chain;
    if (!functionsGatewayUrls || functionsGatewayUrls.length === 0)
        throw Error(`No gatewayUrls found for ${chain.name}.`);

    const secretsManager = new SecretsManager({
        signer,
        functionsRouterAddress: functionsRouter,
        donId: functionsDonIdAlias,
    });
    await secretsManager.initialize();

    const { result } = await secretsManager.listDONHostedEncryptedSecrets(functionsGatewayUrls);
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
