import { Address } from "viem";

import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { deployRouter } from "../deploy/ConceroRouter";
import { deployVerifier } from "../deploy/ConceroVerifier";
import { setRouterSupportedChains } from "../tasks/setRouterSupportedChains";
import { getFallbackClients } from "../utils";
import { setRouterPriceFeeds } from "./setRouterPriceFeeds";
import { setVerifierPriceFeeds } from "./setVerifierPriceFeeds";

async function deployContracts(
	mockCLFRouter: Address,
): Promise<{ mockCLFRouter: any; conceroVerifier: any; conceroRouter: any }> {
	const hre: HardhatRuntimeEnvironment = require("hardhat");
	const { abi: mockCLFRouterAbi } = await import(
		"../artifacts/contracts/mocks/MockCLFRouter.sol/MockCLFRouter.json"
	);
	const { abi: conceroRouterAbi } = await import(
		"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);
	const conceroNetwork = conceroNetworks[hre.network.name];
	const { walletClient } = getFallbackClients(conceroNetwork);

	// DEPLOYMENTS
	const conceroVerifier = await deployVerifier(hre, { clfParams: { router: mockCLFRouter } });
	const conceroRouter = await deployRouter(hre, { conceroVerifier: conceroVerifier.address });

	// VARIABLE SETTING
	await setVerifierPriceFeeds(conceroVerifier.address, walletClient);
	await setRouterPriceFeeds(conceroRouter.address, walletClient);
	await setRouterSupportedChains(conceroRouter.address, walletClient, {
		chainSelectors: [1n, 137n],
		supportedStates: [true, true],
	});
	await walletClient.writeContract({
		address: mockCLFRouter,
		abi: mockCLFRouterAbi,
		functionName: "setConsumer",
		args: [conceroVerifier.address],
		account: walletClient.account,
	});

	return { conceroVerifier, conceroRouter };
}

export { deployContracts };
