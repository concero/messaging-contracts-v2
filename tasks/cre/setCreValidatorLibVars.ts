import { ConceroTestnetNetworkNames, conceroNetworks } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, PublicClient } from "viem";

import {
	ethersSignerCallContract,
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

export async function setCreDonSigners(
	conceroNetworkName: ConceroTestnetNetworkNames,
	hre: HardhatRuntimeEnvironment,
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

	const signersToSet = [];

	const envKey = `CRE_DON_SIGNERS_${conceroNetwork.type.toUpperCase()}`;
	const donSigners = getEnvVar(envKey)
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

	if (getTrezorDeployEnabled()) {
		hash = await ethersSignerCallContract(
			hre,
			validatorLib,
			validatorLibAbi,
			"setAllowedSigners",
			...functionArgs,
		);
	} else {
		hash = await walletClient.writeContract({
			address: validatorLib,
			abi: validatorLibAbi,
			functionName: "setAllowedSigners",
			args: functionArgs,
		});
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setAllowedSigners", conceroNetworkName);
}

async function setExpectedSignersCount(
	conceroNetworkName: ConceroTestnetNetworkNames,
	hre: HardhatRuntimeEnvironment,
) {
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

	const minSignersCount = getEnvVar(`CRE_MIN_SIGNERS_COUNT_${conceroNetwork.type.toUpperCase()}`);

	if (currentExpectedSignersCount === minSignersCount) {
		return;
	}

	let hash;

	const functionArgs = [minSignersCount];

	if (getTrezorDeployEnabled()) {
		hash = await ethersSignerCallContract(
			hre,
			validatorLib,
			validatorLibAbi,
			"setMinSignersCount",
			...functionArgs,
		);
	} else {
		hash = await walletClient.writeContract({
			address: validatorLib,
			abi: validatorLibAbi,
			functionName: "setMinSignersCount",
			args: functionArgs,
		});
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setMinSignersCount", conceroNetworkName);
}

export async function setIsWorkflowIdAllowed(
	conceroNetworkName: ConceroTestnetNetworkNames,
	hre: HardhatRuntimeEnvironment,
) {
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

	if (getTrezorDeployEnabled()) {
		hash = await ethersSignerCallContract(
			hre,
			validatorLib,
			validatorLibAbi,
			"setIsWorkflowIdAllowed",
			...functionArgs,
		);
	} else {
		hash = await walletClient.writeContract({
			address: validatorLib,
			abi: validatorLibAbi,
			functionName: "setIsWorkflowIdAllowed",
			args: functionArgs,
		});
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setIsWorkflowIdAllowed", conceroNetworkName);
}

export async function setDstChainVerificationGasLimit(
	conceroNetworkName: ConceroTestnetNetworkNames,
	hre: HardhatRuntimeEnvironment,
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

	if (getTrezorDeployEnabled()) {
		hash = await ethersSignerCallContract(
			hre,
			validatorLib,
			validatorLibAbi,
			"setDstChainGasLimits",
			...functionArgs,
		);
	} else {
		hash = await walletClient.writeContract({
			address: validatorLib,
			abi: validatorLibAbi,
			functionName: "setDstChainGasLimits",
			args: functionArgs,
		});
	}

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setDstChainGasLimits", conceroNetworkName);
}

export async function setCreValidatorLibVars(conceroNetworkName: ConceroTestnetNetworkNames) {
	const hre = require("hardhat");

	await setCreDonSigners(conceroNetworkName, hre);
	await setExpectedSignersCount(conceroNetworkName, hre);
	await setIsWorkflowIdAllowed(conceroNetworkName, hre);
	await setDstChainVerificationGasLimit(conceroNetworkName, hre);
}
