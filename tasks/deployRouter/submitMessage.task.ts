import { task } from "hardhat/config";

import { type HardhatRuntimeEnvironment } from "hardhat/types";
import { Hex, encodeAbiParameters, encodePacked } from "viem";
import { privateKeyToAccount } from "viem/accounts";

import { conceroNetworks } from "../../constants";
import { ConceroTestnetNetworkNames } from "../../constants/conceroNetworks";
import { getEnvVar, getFallbackClients, getNetworkEnvKey, log } from "../../utils";

async function submitMessage(networkName: ConceroTestnetNetworkNames) {
	const network = conceroNetworks[networkName];
	const { walletClient, publicClient } = getFallbackClients(
		network,
		privateKeyToAccount("0x" + getEnvVar("RELAYER_PRIVATE_KEY")),
	);

	const conceroRouter = getEnvVar(`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(networkName)}`);
	const { abi } = await import(
		"../../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
	);

	const rawReport =
		"0x015b57fa195b078bf360ec0f239f19a8f58ad7927b92d47d0bcb81c385dd2d1cb4692cb0080000000100000001005abdaec2b4e01b66d0b021ecb27d59ccf2868968de657c7ded9c37a3b03a1066666634313464303336dddddb8a8e41c194ac6542a0ad7ba663a72741e0000448147a8e75ea1c6ce3aae570c4b1e0b5ae79aae561d161634807f91ee3c510eb";
	const reportContext =
		"0x000e8ce31db48e5e44619d24d9dadfc5f22a34db8205b2b25cd831eab02244c5000000000000000000000000000000000000000000000000000000004d7da3000000000000000000000000000000000000000000000000000000000000000000";
	const signatures = [
		"0xde8e357110d584942fb766cfafb24cc91697d7f6259b680d3b44f3f01055abdf176fbf6d83034423fd7362d37a204bebb5e4ccd9fc52807f43337c877d961b9f00",
		"0x2ab6623b67138626e92af30bbf0a8abea0a9d752f87afaeb19d47e37d5fcf2966f53eaa1fac92faab9af36242043727824e5354f8b023a02e6398e80d8cf92da00",
		"0x643971d7bb0b6d9d81c8862b90fa8ceeed9a0b6e1451fda7857c17d6e647dd22381593a0b9dd3a2048882eac06a4076c2299eb769840f1d2132f504da05a115c00",
		"0x97bf835176d22bca272810e803e1069e84d6b4271a26177d4b0f46534d7144995a11c9c9ede1157f919a880fea9fa52554bb1f319331f68d72f60ac032ef00ea00",
		"0xef2ad81b321b221b3173e49bd186fd1dd4546eda763bc6cdc1748fddbca46001001802ec9d5a631ff02682c0ef1f47ba70b49dcf59ce38506253696a21770f4401",
		"0x797aa4f871b9d6028bd61f92858718742be1e64fd50236d085b867981e16a2db0d879417cb1deff2ca9dd58d70dc1818d4e504d538db77e158f2ebf784da18ab00",
		"0x9ddbeb83f4160fc2bf3dc86a8878f36e2a9078d501eb6142df4631d0f5652e3903e73e00ba06ab996f97b7e00bd971088ac3a006c7399391c7c406dd9f275dd900",
		"0x28239ee85fd87ebbe39ca370072595b910e439ea81339b290d6299e0991a516367ebea5d73ec0d7dde7aebba727a4b5b6fe33b54c07af9dc122ac6568b788ff501",
	];
	const messageReceipt =
		"0x01013882066eee000000000000000000000000000000000000000000000000000000000000000a00001c07035637b260fbb1021a26bfe016306ecd09f3eb0000000000000000000018b87c9c797d6a888536eda952c5fb2b66351cc5fd000493e0000001000000010000000000010000060100000186a000000c48656c6c6f20776f726c6421";

	const validations = encodePacked(
		["bytes", "bytes", "bytes"],
		[
			rawReport as Hex,
			reportContext as Hex,
			encodeAbiParameters([{ type: "bytes[]" }], [signatures as Hex[]]),
		],
	);

	const args = {
		messageReceipt,
		validations: [validations],
		validatorLibs: [
			getEnvVar(`CONCERO_CRE_VALIDATOR_LIB_PROXY_${getNetworkEnvKey(networkName)}`),
		],
		relayerLib: getEnvVar(`CONCERO_RELAYER_LIB_PROXY_${getNetworkEnvKey(networkName)}`),
	};

	const hash = await walletClient.writeContract({
		address: conceroRouter,
		abi,
		functionName: "submitMessage",
		args: [args.messageReceipt, args.validations, args.validatorLibs, args.relayerLib],
	});

	const { status } = await publicClient.waitForTransactionReceipt({ hash });

	log(status + " : " + hash, "submitMessage", networkName);
}

task("submit-message", "").setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
	await submitMessage(hre.network.name);
});

export { submitMessage };
