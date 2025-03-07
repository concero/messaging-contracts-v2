import { Address } from "viem";

import { task } from "hardhat/config";
import { type HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../constants";
import { deployRouter } from "../deploy/ConceroRouter";
import { deployVerifier } from "../deploy/ConceroVerifier";
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
	const conceroNetwork = conceroNetworks[hre.network.name];
	const { publicClient, walletClient } = getFallbackClients(conceroNetwork);

	const conceroVerifier = await deployVerifier(hre, { clfParams: { router: mockCLFRouter } });
	const conceroRouter = await deployRouter(hre, { conceroVerifier: conceroVerifier.address });

	await setVerifierPriceFeeds(conceroVerifier.address, walletClient);
	await setRouterPriceFeeds(conceroRouter.address, walletClient);
	await walletClient.writeContract({
		address: mockCLFRouter,
		abi: mockCLFRouterAbi,
		functionName: "setConsumer",
		args: [conceroVerifier.address],
		account: walletClient.account,
	});

	return { conceroVerifier, conceroRouter };
}

task("operator-setup", "Setup the operator").setAction(async () => {
	await deployContracts();
});

export { deployContracts };
