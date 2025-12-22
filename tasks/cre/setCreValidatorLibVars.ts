import { getNetworkEnvKey } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Address, PublicClient } from "viem";

import { ConceroTestnetNetworkNames, conceroNetworks } from "../../constants/conceroNetworks";
import { getEnvVar, getFallbackClients, log } from "../../utils";
import { getTrezorDeployEnabled } from "../../utils/getTrezorDeployEnabled";
import { ethersSignerCallContract } from "../utils/ethersSignerCallContract";

const donSigners = [
	"0x4d7D71C7E584CfA1f5c06275e5d283b9D3176924",
	"0x1A89c98E75983Ec384AD8e83EAf7D0176eEaF155",
	"0xdE5CD1dD4300A0b4854F8223add60D20e1dFe21b",
	"0x4D6CFd44F94408a39fB1af94a53c107A730ba161",
	"0xF3BAa9A99B5ad64f50779F449Bac83bAAC8bfDb6",
	"0xD7F22fB5382ff477d2fF5c702cAB0EF8abf18233",
	"0xcdf20F8FFD41B02c680988b20e68735cc8C1ca17",
	"0xff9b062fcCb2f042311343048b9518068370F837",
	"0x4f99b550623e77B807df7cbED9C79D55E1163B48",
	"0xe55fcaf921e76c6bbcf9415bba12b1236f07b0c3",
];

const workflowId = "0x00021574e0f1aafe9524d841a7707ec999504a4237b588fa1d44e6112dec42c4";

const dstChainGasLimit = 100_000n;

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

	if (currentExpectedSignersCount === donSigners.length - 3) {
		return;
	}

	let hash;

	const functionArgs = [donSigners.length - 3];

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

		if (BigInt(currentGasLimit) === dstChainGasLimit) continue;

		dstChainSelectorsToUpdate.push(conceroNetworks[conceroNetwork].chainSelector);
	}

	if (dstChainSelectorsToUpdate.length === 0) return;

	const functionArgs = [
		dstChainSelectorsToUpdate,
		dstChainSelectorsToUpdate.map(_ => dstChainGasLimit),
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
