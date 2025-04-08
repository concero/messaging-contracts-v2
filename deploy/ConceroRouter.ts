import { zeroAddress } from "viem";

import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks, networkEnvKeys } from "../constants";
import { getConceroVerifierNetwork } from "../constants/conceroNetworks";
import { ConceroNetworkNames, NetworkType } from "../types/ConceroNetwork";
import { getEnvVar, getGasParameters, log, updateEnvVariable } from "../utils/";

function getCLFDonSigners(networkType: NetworkType) {
	let networkName: ConceroNetworkNames;
	switch (networkType) {
		case "mainnet":
			networkName = "arbitrum";
			break;

		case "testnet":
			networkName = "arbitrumSepolia";
			break;

		case "localhost":
			networkName = "localhost";
			break;

		default:
			throw new Error(`Invalid network type: ${networkType}`);
	}

	let clfDonSigners = [];
	for (let i = 0; i < 4; i++) {
		clfDonSigners.push(getEnvVar(`CLF_DON_SIGNING_KEY_${i}_${networkEnvKeys[networkName]}`));
	}
	return clfDonSigners;
}

type DeployArgs = {
	chainSelector: bigint;
	usdc: string;
	conceroVerifier: string;
	conceroVerifierSubId: string;
	clfSigners: string[];
};

type DeploymentFunction = (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
) => Promise<Deployment>;

const deployRouter: DeploymentFunction = async function (
	hre: HardhatRuntimeEnvironment,
	overrideArgs?: Partial<DeployArgs>,
): Promise<Deployment> {
	const { deployer } = await hre.getNamedAccounts();
	const { deploy } = hre.deployments;
	const { name } = hre.network;

	const chain = conceroNetworks[name as ConceroNetworkNames];
	const { type: networkType } = chain;

	const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(chain);

	const conceroVerifierNetwork = getConceroVerifierNetwork(networkType);

	const defaultArgs: DeployArgs = {
		chainSelector: chain.chainSelector,
		// usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
		usdc: zeroAddress,
		conceroVerifier: getEnvVar(
			`CONCERO_VERIFIER_PROXY_${networkEnvKeys[conceroVerifierNetwork.name]}`,
		),
		conceroVerifierSubId: getEnvVar(`CLF_SUBID_${networkEnvKeys[conceroVerifierNetwork.name]}`),
		clfSigners: getCLFDonSigners(networkType),
	};

	const args: DeployArgs = {
		...defaultArgs,
		...overrideArgs,
	};

	const deployment = await deploy("ConceroRouter", {
		from: deployer,
		args: [
			args.chainSelector,
			args.conceroVerifier,
			args.conceroVerifierSubId,
			args.clfSigners,
		],
		log: true,
		autoMine: true,
		maxFeePerGas,
		maxPriorityFeePerGas,
	});

	log(`Deployed at: ${deployment.address}`, "deployRouter", name);
	updateEnvVariable(
		`CONCERO_ROUTER_${networkEnvKeys[name]}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

export { deployRouter };
export default deployRouter;
deployRouter.tags = ["ConceroRouter"];
