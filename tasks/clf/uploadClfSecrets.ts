import { SecretsManager } from "@chainlink/functions-toolkit";

import { CLF_MAINNET_TTL, CLF_TESTNET_TTL, networkEnvKeys, secrets } from "../../constants";
import { gatewayUrls } from "../../constants/clf/gatewayUrls";
import { ConceroNetwork } from "../../types/ConceroNetwork";
import { getEnvVar, getEthersSignerAndProvider, log, updateEnvVariable } from "../../utils";
import { listSecrets } from "./listClfSecrets";

export async function uploadClfSecrets(chains: ConceroNetwork[], slotid: number) {
	const slotId = parseInt(slotid);

	for (const chain of chains) {
		const { url, name } = chain;
		const { signer } = getEthersSignerAndProvider(url);
		const minutesUntilExpiration = chain.type === "mainnet" ? CLF_MAINNET_TTL : CLF_TESTNET_TTL;

		console.log({
			signer,
			functionsRouterAddress: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
			donId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
		});

		const secretsManager = new SecretsManager({
			signer,
			functionsRouterAddress: getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
			donId: getEnvVar(`CLF_DONID_${networkEnvKeys[name]}_ALIAS`),
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
			gatewayUrls: gatewayUrls[chain.type],
			slotId,
			minutesUntilExpiration,
		});

		log(
			`DONSecrets uploaded to ${name}. slot_id: ${slotId}, version: ${version}, ttl: ${minutesUntilExpiration}`,
			"donSecrets/upload",
		);

		await listSecrets(chain);

		updateEnvVariable(
			`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`,
			version,
			"../../../.env.clf",
		);
	}
}
