import { readFileSync } from "fs";
import { resolve } from "path";

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

import { conceroNetworks } from "../../constants";
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
		getEnvVar(`USDC_${getNetworkEnvKey(name)}`),
		getEnvVar(`CLF_ROUTER_${getNetworkEnvKey(name)}`),
		getEnvVar(`CLF_DONID_${getNetworkEnvKey(name)}`),
		getEnvVar(`CLF_SUBID_${getNetworkEnvKey(name)}`),
		getEnvVar(`CLF_DON_SECRETS_VERSION_${getNetworkEnvKey(name)}`),
		CLF_DON_HOSTED_SECRETS_SLOT,
		getEnvVar(`CLF_PREMIUM_FEE_USD_BPS_${getNetworkEnvKey(name)}`),
		100_000n, // clfCallbackGasLimit
		getHashSum(requestReportJs),
		getHashSum(messageReportJs),
	];

	const verifier = m.contract("ConceroVerifier", constructorArgs, {
		from: deployer,
	});

	updateEnvVariable(
		`CONCERO_VERIFIER_${getNetworkEnvKey(name)}`,
		verifier.address,
		`deployments.${type}`,
	);

	return {
		verifier,
	};
});
