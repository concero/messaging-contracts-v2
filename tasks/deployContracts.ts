import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { Address } from "viem";

import { conceroNetworks } from "../constants";
import { deployPriceFeed } from "../deploy/ConceroPriceFeed";
import { deployRouter } from "../deploy/ConceroRouter";
import { setLastGasPrices } from "../tasks/setLastGasPrices";
import { setNativeUsdRate } from "../tasks/setNativeUsdRate";
import { setRouterSupportedChains } from "../tasks/setRouterSupportedChains";
import { deployVerifierHarness } from "../test/operator/utils/deployConceroVerifierHarness";
import { getFallbackClients } from "../utils";
import { setVerifierGasFeeConfig } from "./utils/setVerifierGasFeeConfig";

async function deployContracts(mockCLFRouter: Address): Promise<{
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
	const conceroPriceFeed = await deployPriceFeed(hre, {
		feedUpdater: walletClient.account?.address,
	});
	const conceroVerifier = await deployVerifierHarness(hre, {
		clfParams: { router: mockCLFRouter },
		conceroPriceFeed: conceroPriceFeed.address,
	});
	const conceroRouter = await deployRouter(hre, {
		conceroVerifier: conceroVerifier.address,
		conceroPriceFeed: conceroPriceFeed.address,
	});

	// VARIABLE SETTING
	await setNativeUsdRate(conceroPriceFeed.address, walletClient, 1000000000000000000n);
	await setLastGasPrices(conceroPriceFeed.address, walletClient, {
		chainSelectors: [1n],
		lastGasPrices: [1n],
	});
	await setRouterSupportedChains(conceroRouter.address, walletClient, {
		chainSelectors: [1n, 137n],
		supportedStates: [true, true],
	});
	await setVerifierGasFeeConfig(conceroNetwork, conceroVerifier.address, {
		vrfMsgReportRequestGasOverhead: 1,
		clfGasPriceOverEstimationBps: 1,
		clfCallbackGasOverhead: 1,
		clfCallbackGasLimit: 1,
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
