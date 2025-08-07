import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { Address } from "viem";

import { conceroNetworks } from "../constants";
import { deployPriceFeed } from "../deploy/ConceroPriceFeed";
import { deployRouter } from "../deploy/ConceroRouter";
import { deployVerifier } from "../deploy/ConceroVerifier";
import { setRouterSupportedChains } from "../tasks/setRouterSupportedChains";
import { getFallbackClients } from "../utils";

async function deployContracts(
	mockCLFRouter: Address,
): Promise<{
	mockCLFRouter: any;
	conceroVerifier: any;
	conceroRouter: any;
	conceroPriceFeed: any;
}> {
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
	const conceroPriceFeed = await deployPriceFeed(hre);
	const conceroVerifier = await deployVerifier(hre, {
		clfParams: { router: mockCLFRouter },
		conceroPriceFeed: conceroPriceFeed.address,
	});
	const conceroRouter = await deployRouter(hre, {
		conceroVerifier: conceroVerifier.address,
		conceroPriceFeed: conceroPriceFeed.address,
	});

	// VARIABLE SETTING
	// TODO: set gasFeeConfig on ConceroVerifier
	// TODO: set price feeds on ConceroPriceFeed
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

	return { conceroVerifier, conceroRouter, conceroPriceFeed };
}

export { deployContracts };
