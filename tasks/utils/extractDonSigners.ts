import { HardhatRuntimeEnvironment } from "hardhat/types";

import { conceroNetworks } from "../../constants";
import { donRegistryAbi } from "../../constants";
import { err, getFallbackClients, log } from "../../utils";

interface DONSignerInfo {
	donId: number;
	signers: string[];
	signersAmount: number;
}

export const extractDonSigners = async (
	registry: string,
	startStr: string,
	limitStr: string,
	hre: HardhatRuntimeEnvironment,
): Promise<void> => {
	const start = BigInt(startStr || 0);
	const limit = BigInt(limitStr || 100);

	log(
		`Extracting DON signers from CapabilitiesRegistry with start=${start} and limit=${limit}`,
		"extractDonSigners",
	);

	const { name } = hre.network;
	const network = conceroNetworks[name];

	if (!network) {
		err("Ethereum network not found in conceroNetworks", "extractDonSigners");
		return;
	}
	const { publicClient } = getFallbackClients(network);

	let dons: any[];
	try {
		dons = (await publicClient.readContract({
			address: registry as `0x${string}`,
			abi: donRegistryAbi,
			functionName: "getDONs",
			args: [start, limit],
		})) as any[];
	} catch (error) {
		err(
			`Failed to call getDONs: ${error instanceof Error ? error.message : String(error)}`,
			"extractDonSigners",
		);
		return;
	}

	if (dons.length === 0) {
		log("No DONs found in the specified range", "extractDonSigners");
		return;
	}

	const donSigners: DONSignerInfo[] = [];

	for (const don of dons) {
		const donId = Number(don.id); // uint32 id
		const nodeP2PIds = don.nodeP2PIds; // bytes32[] nodeP2PIds

		if (!Array.isArray(nodeP2PIds)) {
			err(`nodeP2PIds is not an array for DON ${donId}`, "extractDonSigners");
			continue;
		}

		// console.log("don", don);

		const signers: string[] = [];
		for (const p2pId of nodeP2PIds) {
			try {
				const node = (await publicClient.readContract({
					address: registry as `0x${string}`,
					abi: donRegistryAbi,
					functionName: "getNode",
					args: [p2pId],
				})) as any;

				// console.log("node", node);

				const signerBytes = node.signer; // bytes32 signer
				if (typeof signerBytes !== "string" || !signerBytes.startsWith("0x")) {
					err(`Invalid signer format for p2pId ${p2pId}`, "extractDonSigners");
					continue;
				}
				const signerAddress = signerBytes.substring(0, 42);
				signers.push(signerAddress);
			} catch (error) {
				err(
					`Failed to get node for p2pId ${p2pId}: ${error instanceof Error ? error.message : String(error)}`,
					"extractDonSigners",
				);
			}
		}

		if (signers.length > 0) {
			donSigners.push({ donId, signers, signersAmount: signers.length });
		}
	}

	if (donSigners.length === 0) {
		log("No signers found for the DONs", "extractDonSigners");
		return;
	}

	log("Extracted DON signers:", "extractDonSigners");
	const displayData = donSigners.map(info => ({
		"DON ID": info.donId,
		Signers: info.signers.join(","),
		"Signers Amount": info.signersAmount,
	}));

	console.log(JSON.stringify(displayData, null, 2));
};
