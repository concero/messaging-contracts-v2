import { WalletClient } from "viem";

import { log } from "../utils";

export async function setNativeUsdRate(
	conceroPriceFeedAddress: string,
	walletClient: WalletClient,
	nativeUsdRate = 1000000000000000000n,
) {
	const { abi: conceroPriceFeedAbi } = await import(
		"../artifacts/contracts/ConceroPriceFeed/ConceroPriceFeed.sol/ConceroPriceFeed.json"
	);

	const txHash = await walletClient.writeContract({
		address: conceroPriceFeedAddress,
		abi: conceroPriceFeedAbi,
		functionName: "setNativeUsdRate",
		args: [nativeUsdRate],
		account: walletClient.account,
	});
	log(`Transaction hash: ${txHash}`, "setNativeUsdRate");
}
