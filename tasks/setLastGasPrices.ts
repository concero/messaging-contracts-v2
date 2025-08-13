import { WalletClient } from "viem";

import { log } from "../utils";

export async function setLastGasPrices(
	conceroPriceFeedAddress: string,
	walletClient: WalletClient,
	{ chainSelectors = [1], lastGasPrices = [1n] } = {},
) {
	const { abi: conceroPriceFeedAbi } = await import(
		"../artifacts/contracts/ConceroPriceFeed/ConceroPriceFeed.sol/ConceroPriceFeed.json"
	);

	const txHash = await walletClient.writeContract({
		address: conceroPriceFeedAddress,
		abi: conceroPriceFeedAbi,
		functionName: "setLastGasPrices",
		args: [chainSelectors, lastGasPrices],
		account: walletClient.account,
	});
	log(`Transaction hash: ${txHash}`, "setLastGasPrice");
}
