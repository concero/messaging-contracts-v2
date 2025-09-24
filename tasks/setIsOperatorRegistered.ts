import { task } from "hardhat/config";

import { WalletClient } from "viem";

import { conceroNetworks } from "../constants";
import {
	OperatorSlots,
	Namespaces as verifierNamespaces,
} from "../constants/storage/ConceroVerifierStorage";
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
	isRegistered: boolean = true,
) {
	const { abi: conceroVerifierAbi } = await import(
		"../artifacts/contracts/ConceroVerifier/ConceroVerifier.sol/ConceroVerifier.json"
	);

	const operatorAddressBytes32 = `0x${operatorAddress.slice(2).padStart(64, "0")}`;

	const txHash = await walletClient.writeContract({
		address: conceroVerifierAddress,
		abi: conceroVerifierAbi,
		functionName: "setStorage",
		args: [
			verifierNamespaces.OPERATOR,
			BigInt(OperatorSlots.isRegistered),
			operatorAddressBytes32,
			isRegistered ? 1n : 0n,
		],
		account: walletClient.account,
	});

	log(`Transaction hash: ${txHash}`, "setOperatorRegistration");
	log(
		`Operator ${operatorAddress} set as ${isRegistered ? "registered" : "unregistered"}`,
		"setOperatorRegistration",
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
