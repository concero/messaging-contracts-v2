import {
	conceroNetworks,
	ConceroTestnetNetworkNames,
	trezorWriteContract,
} from "@concero/contract-utils";
import { Address, PublicClient } from "viem";

import {
	getEnvVar,
	getFallbackClients,
	getNetworkEnvKey,
	getTrezorDeployEnabled,
	log,
} from "../../utils";
import { getVerificationGasLimit } from "../../utils/getVerificationGasLimit";
import { isDeployToStage } from "../../utils/isDeployToStage";

async function isDonSignerAllowed(
	signer: Address,
	publicClient: PublicClient,
	validatorLib: Address,
	validatorLibAbi: any,
) {
	return publicClient.readContract({
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "isSignerAllowed",
		args: [signer],
	});
}

export async function setCreDonSigners(conceroNetworkName: ConceroTestnetNetworkNames) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];

	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const validatorLib = getEnvVar(
		`CONCERO_CRE_VALIDATOR_LIB_PROXY_${getNetworkEnvKey(conceroNetworkName)}`,
	) as Address;
	const { abi: creValidatorLibAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/CreValidatorLib.sol/CreValidatorLib.json"
	);
	const { abi: ecdsaValidatorAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/EcdsaValidatorLib.sol/EcdsaValidatorLib.json"
	);
	const validatorLibAbi = [...creValidatorLibAbi, ...ecdsaValidatorAbi];

	const signersToSet = [];

	const donSigners = getEnvVar("CRE_DON_SIGNERS")
		.split(",")
		.map(addr => addr.trim() as Address);

	for (const signer of donSigners) {
		const isSignerAllowed = await isDonSignerAllowed(
			signer,
			publicClient,
			validatorLib,
			validatorLibAbi,
		);
		if (isSignerAllowed) continue;
		signersToSet.push(signer);
	}

	if (signersToSet.length === 0) return;

	const isAllowedArr = signersToSet.map(() => true);

	let hash;
	const functionArgs = [signersToSet, isAllowedArr];

	const writeContractParams = {
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "setAllowedSigners",
		args: functionArgs,
	};

	if (getTrezorDeployEnabled()) {
		hash = await trezorWriteContract({ publicClient }, writeContractParams);
	} else {
		hash = await walletClient.writeContract(writeContractParams);
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setAllowedSigners", conceroNetworkName);
}

async function setExpectedSignersCount(conceroNetworkName: ConceroTestnetNetworkNames) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];

	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const validatorLib = getEnvVar(
		`CONCERO_CRE_VALIDATOR_LIB_PROXY_${getNetworkEnvKey(conceroNetworkName)}`,
	);
	const { abi: creValidatorLibAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/CreValidatorLib.sol/CreValidatorLib.json"
	);
	const { abi: ecdsaValidatorAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/EcdsaValidatorLib.sol/EcdsaValidatorLib.json"
	);
	const validatorLibAbi = [...creValidatorLibAbi, ...ecdsaValidatorAbi];

	const currentExpectedSignersCount = await publicClient.readContract({
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "getMinSignersCount",
		args: [],
	});

	const minSignersCount = getEnvVar("CRE_MIN_SIGNERS_COUNT");

	if (currentExpectedSignersCount === minSignersCount) {
		return;
	}

	let hash;

	const functionArgs = [minSignersCount];
	const writeContractParams = {
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "setMinSignersCount",
		args: functionArgs,
	};

	if (getTrezorDeployEnabled()) {
		hash = await trezorWriteContract({ publicClient }, writeContractParams);
	} else {
		hash = await walletClient.writeContract(writeContractParams);
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setMinSignersCount", conceroNetworkName);
}

export async function setIsWorkflowIdAllowed(conceroNetworkName: ConceroTestnetNetworkNames) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];
	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const validatorLib = getEnvVar(
		`CONCERO_CRE_VALIDATOR_LIB_PROXY_${getNetworkEnvKey(conceroNetworkName)}`,
	);
	const { abi: creValidatorLibAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/CreValidatorLib.sol/CreValidatorLib.json"
	);
	const { abi: ecdsaValidatorAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/EcdsaValidatorLib.sol/EcdsaValidatorLib.json"
	);
	const validatorLibAbi = [...creValidatorLibAbi, ...ecdsaValidatorAbi];

	const workflowId = getEnvVar(
		isDeployToStage()
			? "CRE_WORKFLOW_ID_STAGE"
			: conceroNetwork.type === "mainnet"
				? "CRE_WORKFLOW_ID_MAINNET"
				: "CRE_WORKFLOW_ID_TESTNET",
	);

	const isWorkflowAllowed = await publicClient.readContract({
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "isWorkflowIdAllowed",
		args: [workflowId],
	});

	if (isWorkflowAllowed === true) {
		return;
	}
	let hash;
	const functionArgs = [workflowId, true];
	const writeContractParams = {
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "setIsWorkflowIdAllowed",
		args: functionArgs,
	};

	if (getTrezorDeployEnabled()) {
		hash = await trezorWriteContract({ publicClient }, writeContractParams);
	} else {
		hash = await walletClient.writeContract(writeContractParams);
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setIsWorkflowIdAllowed", conceroNetworkName);
}

export async function setDstChainVerificationGasLimit(
	conceroNetworkName: ConceroTestnetNetworkNames,
) {
	const conceroNetwork = conceroNetworks[conceroNetworkName];
	const { walletClient, publicClient } = getFallbackClients(conceroNetwork);
	const validatorLib = getEnvVar(
		`CONCERO_CRE_VALIDATOR_LIB_PROXY_${getNetworkEnvKey(conceroNetworkName)}`,
	) as Address;
	const { abi: creValidatorLibAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/CreValidatorLib.sol/CreValidatorLib.json"
	);
	const { abi: ecdsaValidatorAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/EcdsaValidatorLib.sol/EcdsaValidatorLib.json"
	);
	const validatorLibAbi = [...creValidatorLibAbi, ...ecdsaValidatorAbi];

	const dstChainSelectorsToUpdate = [];

	for (const conceroNetwork in conceroNetworks) {
		const currentGasLimit = await publicClient.readContract({
			address: validatorLib,
			abi: validatorLibAbi,
			functionName: "getDstChainGasLimit",
			args: [conceroNetworks[conceroNetwork].chainSelector],
		});

		const dstChainGasLimit = getVerificationGasLimit(
			conceroNetworks[conceroNetwork].chainSelector,
		);

		if (currentGasLimit === dstChainGasLimit) continue;

		dstChainSelectorsToUpdate.push(conceroNetworks[conceroNetwork].chainSelector);
	}

	if (dstChainSelectorsToUpdate.length === 0) return;

	const functionArgs = [
		dstChainSelectorsToUpdate,
		dstChainSelectorsToUpdate.map(chainSelector => getVerificationGasLimit(chainSelector)),
	];

	let hash;
	const writeContractParams = {
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "setDstChainGasLimits",
		args: functionArgs,
	};

	if (getTrezorDeployEnabled()) {
		hash = await trezorWriteContract({ publicClient }, writeContractParams);
	} else {
		hash = await walletClient.writeContract(writeContractParams);
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setDstChainGasLimits", conceroNetworkName);
}

export async function setCreValidatorLibVars(conceroNetworkName: ConceroTestnetNetworkNames) {
	await setCreDonSigners(conceroNetworkName);
	await setExpectedSignersCount(conceroNetworkName);
	await setIsWorkflowIdAllowed(conceroNetworkName);
	await setDstChainVerificationGasLimit(conceroNetworkName);
}
