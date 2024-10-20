import { SecretsManager } from "@chainlink/functions-toolkit";
import secrets from "../../constants/CLFSecrets";
import updateEnvVariable from "../../utils/updateEnvVariable";
import log from "../../utils/log";
import { listSecrets } from "./listClfSecrets";
import { getEnvVar, getEthersSignerAndProvider } from "../../utils";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { networkEnvKeys } from "../../constants";
import { clfGatewayUrls } from "../../constants/clfGatewayUrls";
import { CLF_MAINNET_TTL, CLF_TESTNET_TTL } from "../../constants/clfTtl";

export async function uploadClfSecrets(chains: ConceroNetwork[], slotid: number) {
    const slotId = parseInt(slotid);

    for (const chain of chains) {
        const { url, name } = chain;
        const { signer } = getEthersSignerAndProvider(url);
        const minutesUntilExpiration = chain.type === "mainnet" ? CLF_MAINNET_TTL : CLF_TESTNET_TTL;

        const secretsManager = new SecretsManager({
            signer,
            functionsRouterAddress: getEnvVar(`CLF_ROUTER${networkEnvKeys[name]}`),
            donId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
        });
        await secretsManager.initialize();

        if (!secrets) {
            console.error("No secrets to upload.");
            return;
        }

        console.log("Uploading secrets to DON for network:", name);
        const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);

        const { version } = await secretsManager.uploadEncryptedSecretsToDON({
            encryptedSecretsHexstring: encryptedSecretsObj.encryptedSecrets,
            gatewayUrls: clfGatewayUrls[chain.type],
            slotId,
            minutesUntilExpiration,
        });

        log(
            `DONSecrets uploaded to ${name}. slot_id: ${slotId}, version: ${version}, ttl: ${minutesUntilExpiration}`,
            "donSecrets/upload",
        );

        await listSecrets(chain);

        updateEnvVariable(`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`, version, "../../../.env.clf");
    }
}
