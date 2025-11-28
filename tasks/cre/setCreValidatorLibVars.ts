import { getNetworkEnvKey } from "@concero/contract-utils";
import { Address, PublicClient } from "viem";

import { ConceroTestnetNetworkNames, conceroNetworks } from "../../constants/conceroNetworks";
import { getEnvVar, getFallbackClients, log } from "../../utils";

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
];

const workflowId = "0x005abdaec2b4e01b66d0b021ecb27d59ccf2868968de657c7ded9c37a3b03a10";

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
	);
	const { abi: creValidatorLibAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/CreValidatorLib.sol/CreValidatorLib.json"
	);
	const { abi: ecdsaValidatorAbi } = await import(
		"../../artifacts/contracts/validators/CreValidatorLib/EcdsaValidatorLib.sol/EcdsaValidatorLib.json"
	);
	const validatorLibAbi = [...creValidatorLibAbi, ...ecdsaValidatorAbi];

	const signersToSet = [];

	for (const signer of donSigners) {
		if (await isDonSignerAllowed(signer, publicClient, validatorLib, validatorLibAbi)) continue;
		signersToSet.push(signer);
	}

	if (signersToSet.length === 0) return;

	const isAllowedArr = signersToSet.map(_ => true);

	const hash = await walletClient.writeContract({
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "setAllowedSigners",
		args: [signersToSet, isAllowedArr],
	});

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
		functionName: "getExpectedSignersCount",
		args: [],
	});

	if (currentExpectedSignersCount === donSigners.length) {
		return;
	}

	const hash = await walletClient.writeContract({
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "setExpectedSignersCount",
		args: [donSigners.length],
	});

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setExpectedSignersCount", conceroNetworkName);
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

	const isWorkflowAllowed = await publicClient.readContract({
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "isWorkflowIdAllowed",
		args: [workflowId],
	});

	if (isWorkflowAllowed === true) {
		return;
	}

	const hash = await walletClient.writeContract({
		address: validatorLib,
		abi: validatorLibAbi,
		functionName: "setIsWorkflowIdAllowed",
		args: [workflowId, true],
	});

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "setIsWorkflowIdAllowed", conceroNetworkName);
}

export async function setCreValidatorLibVars(conceroNetworkName: ConceroTestnetNetworkNames) {
	await setCreDonSigners(conceroNetworkName);
	await setExpectedSignersCount(conceroNetworkName);
	await setIsWorkflowIdAllowed(conceroNetworkName);
}
