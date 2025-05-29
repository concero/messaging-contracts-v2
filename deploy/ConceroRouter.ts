import { zeroAddress } from "viem";

import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { getNetworkEnvKey } from "@concero/contract-utils";

import { conceroNetworks } from "../constants";
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
		clfDonSigners.push(getEnvVar(`CLF_DON_SIGNING_KEY_${i}_${getNetworkEnvKey(networkName)}`));
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
		usdc: zeroAddress,
		conceroVerifier: getEnvVar(
			`CONCERO_VERIFIER_PROXY_${getNetworkEnvKey(conceroVerifierNetwork.name)}`,
		),
		conceroVerifierSubId: getEnvVar(
			`CLF_SUBID_${getNetworkEnvKey(conceroVerifierNetwork.name)}`,
		),
		clfSigners: getCLFDonSigners(networkType),
		feedUpdater: process.env.FEED_UPDATER_ADDRESS,
	};

	const args: DeployArgs = {
		...defaultArgs,
		...overrideArgs,
	};

	const deployment = await deploy("ConceroRouter", {
		from: deployer,
		args: [
			args.chainSelector,
			args.feedUpdater,
			args.conceroVerifier,
			args.conceroVerifierSubId,
			args.clfSigners,
		],
		log: true,
		autoMine: true,
		// maxFeePerGas,
		// maxPriorityFeePerGas,
	});

	log(`Deployed at: ${deployment.address}`, "deployRouter", name);
	updateEnvVariable(
		`CONCERO_ROUTER_${getNetworkEnvKey(name)}`,
		deployment.address,
		`deployments.${networkType}`,
	);

	return deployment;
};

export { deployRouter };
export default deployRouter;
deployRouter.tags = ["ConceroRouter"];
