import { getNetworkEnvKey } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, zeroAddress } from "viem";

import { conceroNetworks } from "../../../constants";
import { getConceroVerifierNetwork } from "../../../constants/conceroNetworks";
import { deployRouter, deployVerifier } from "../../../deploy";
import { getCLFDonSigners } from "../../../deploy/ConceroRouter";
import { deployContracts, setRouterSupportedChains } from "../../../tasks";
import { getEnvVar, getFallbackClients, log, updateEnvVariable } from "../../../utils";

export async function deployPseudoRemoteConceroRouter(
	conceroVerifierAddress: Address,
): Promise<{ conceroRouter: any }> {
	const { abi: mockCLFRouterAbi } = await import(
		"../../../artifacts/contracts/mocks/MockCLFRouter.sol/MockCLFRouter.json"
	);
	const { abi: conceroRouterAbi } = await import(
		"../../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	const hre: HardhatRuntimeEnvironment = require("hardhat");

	const { name } = hre.network;
	const chain = conceroNetworks[name];
	const { type: networkType } = chain;

	const conceroNetwork = conceroNetworks[hre.network.name];
	const { walletClient } = getFallbackClients(conceroNetwork);
	const { deploy } = hre.deployments;
	const { deployer } = await hre.getNamedAccounts();
	const conceroVerifierNetwork = getConceroVerifierNetwork(networkType);

	const args = {
		chainSelector: 137n,
		usdc: zeroAddress,
		conceroPriceFeed: getEnvVar(
			`CONCERO_PRICE_FEED_PROXY_${getNetworkEnvKey(conceroVerifierNetwork.name)}`,
		),
		conceroVerifier: getEnvVar(
			`CONCERO_VERIFIER_PROXY_${getNetworkEnvKey(conceroVerifierNetwork.name)}`,
		),
		conceroVerifierSubId: getEnvVar(
			`CLF_SUBID_${getNetworkEnvKey(conceroVerifierNetwork.name)}`,
		),
		clfSigners: getCLFDonSigners(networkType),
		feedUpdater: process.env.FEED_UPDATER_ADDRESS,
	};

	const deployment = await deploy("ConceroRouter", {
		from: deployer,
		args: [
			args.chainSelector,
			args.conceroPriceFeed,
			args.conceroVerifier,
			args.conceroVerifierSubId,
			args.clfSigners,
		],
		log: true,
		autoMine: true,
		// maxFeePerGas,
		// maxPriorityFeePerGas,
	});

	log(`Deployed at: ${deployment.address}`, "deployPseudoRemoteConceroRouter", name);
	updateEnvVariable(
		`CONCERO_ROUTER_LOCALHOST_DST`,
		deployment.address,
		`deployments.${networkType}`,
	);

	// VARIABLE SETTING
	// TODO: set gasFeeConfig
	// TODO: set price feeds on ConceroPriceFeed
	await setRouterSupportedChains(deployment.address, walletClient, {
		chainSelectors: [1n, 137n],
		supportedStates: [true, true],
	});

	return { conceroRouter: deployment };
}

export { deployContracts };
