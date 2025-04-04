import { readFileSync } from "fs";
import { resolve } from "path";

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

import { conceroNetworks, networkEnvKeys } from "../../constants";
import { CLF_DON_HOSTED_SECRETS_SLOT } from "../../constants/clf/secretsConfig";
import { ConceroNetworkNames } from "../../types/ConceroNetwork";
import { getEnvVar, getHashSum, updateEnvVariable } from "../../utils";

/*
Hardhat Ignition doesn't seem to provide a way (yet) to retrieve the contract addresses directly after deployment, particularly because it creates Future artifacts corresponding to the contracts during deployment.
*/
const requestReportJs = readFileSync(
	resolve(__dirname, "../../clf/dist/requestReport.min.js"),
	"utf8",
);
const messageReportJs = readFileSync(
	resolve(__dirname, "../../clf/dist/messageReport.min.js"),
	"utf8",
);

export default buildModule("ConceroVerifier", m => {
	const deployer = m.getAccount(0);

	const { name } = hre.network;
	const { type } = conceroNetworks[name as ConceroNetworkNames];

	const constructorArgs = [
		// getEnvVar(`CONCERO_CHAIN_SELECTOR_${networkEnvKeys[name]}`),
		getEnvVar(`USDC_${networkEnvKeys[name]}`),
		getEnvVar(`CLF_ROUTER_${networkEnvKeys[name]}`),
		getEnvVar(`CLF_DONID_${networkEnvKeys[name]}`),
		getEnvVar(`CLF_SUBID_${networkEnvKeys[name]}`),
		getEnvVar(`CLF_DON_SECRETS_VERSION_${networkEnvKeys[name]}`),
		CLF_DON_HOSTED_SECRETS_SLOT,
		getEnvVar(`CLF_PREMIUM_FEE_USD_BPS_${networkEnvKeys[name]}`),
		100_000n, // clfCallbackGasLimit
		getHashSum(requestReportJs),
		getHashSum(messageReportJs),
	];

	const verifier = m.contract("ConceroVerifier", constructorArgs, {
		from: deployer,
	});

	updateEnvVariable(
		`CONCERO_VERIFIER_${networkEnvKeys[name]}`,
		verifier.address,
		`deployments.${type}`,
	);

	return {
		verifier,
	};
});
