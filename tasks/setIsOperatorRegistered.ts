import { task } from "hardhat/config";

import { WalletClient } from "viem";

import { conceroNetworks } from "../constants";
import { getEnvAddress, getFallbackClients, log } from "../utils";

/**
 * Sets an operator as registered in the ConceroOperator contract
 * @param conceroVerifierAddress Address of the ConceroVerifier contract
 * @param operatorAddress Address of the operator to register
 * @param walletClient Wallet client to use for the transaction
 * @param isRegistered Whether the operator should be registered (true) or unregistered (false)
 */
export async function setIsOperatorRegistered(
	conceroVerifierAddress: string,
	operatorAddress: string,
	walletClient: WalletClient,
	isRegistered: boolean,
) {
	const { abi: conceroVerifierHarnessAbi } = await import(
		"../artifacts/contracts/harnesses/ConceroVerifierHarness.sol/ConceroVerifierHarness.json"
	);

	const isAlreadyRegistered = await walletClient.readContract({
		address: conceroVerifierAddress,
		abi: conceroVerifierHarnessAbi,
		functionName: "isOperatorRegistered",
		args: [operatorAddress],
	});

	if (isAlreadyRegistered) {
		return;
	}

	const chainType = 0n; // EVM

	const txHash = await walletClient.writeContract({
		address: conceroVerifierAddress,
		abi: conceroVerifierHarnessAbi,
		functionName: "exposed_operatorRegistration",
		args: [chainType, operatorAddress, isRegistered],
		account: walletClient.account,
	});

	log(`Transaction hash: ${txHash}`, "exposed_operatorRegistration");
	log(
		`Operator ${operatorAddress} set as ${isRegistered ? "registered" : "unregistered"}`,
		"exposed_operatorRegistration",
	);
}

task("set-operator-registration", "Set an operator as registered or unregistered")
	.addParam("operator", "Address of the operator")
	.addOptionalParam(
		"status",
		"Whether the operator should be registered (true) or unregistered (false)",
	)
	.setAction(async (taskArgs, hre) => {
		const [verifier] = getEnvAddress("verifierProxy", hre.network.name);
		const conceroNetwork = conceroNetworks[hre.network.name];
		const { walletClient } = getFallbackClients(conceroNetwork);

		const isRegistered = taskArgs.status === "true" || taskArgs.status === undefined;

		await setIsOperatorRegistered(verifier, taskArgs.operator, walletClient, isRegistered);
	});
