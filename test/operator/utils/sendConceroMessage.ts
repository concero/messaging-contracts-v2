import { PublicClient, WalletClient, decodeEventLog, parseUnits } from "viem";

import { globalConfig } from "@concero/v2-operators/src/constants";

export async function sendConceroMessage(
	walletClient: WalletClient,
	publicClient: PublicClient,
	clientAddress: string,
) {
	const { abi: exampleClientAbi } = await import(
		"../../../artifacts/contracts/ConceroClient/ConceroClientExample.sol/ConceroClientExample.json"
	);

	const txHash = await walletClient.writeContract({
		account: walletClient.account,
		address: clientAddress,
		abi: exampleClientAbi,
		functionName: "sendConceroMessage",
		args: [clientAddress, 1n],
		value: parseUnits("0.01", 18),
		gas: 10000000n,
	});

	const txReceipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

	const foundMessageSentLog = txReceipt.logs.find(log => {
		try {
			const decoded = decodeEventLog({
				abi: globalConfig.ABI.CONCERO_ROUTER,
				data: log.data,
				topics: log.topics,
			});

			return decoded.eventName === "ConceroMessageSent";
		} catch {
			return false;
		}
	});

	if (!foundMessageSentLog) {
		throw new Error("ConceroMessageSent event not found in logs");
	}

	const decodedEvent = decodeEventLog({
		abi: globalConfig.ABI.CONCERO_ROUTER,
		data: foundMessageSentLog.data,
		topics: foundMessageSentLog.topics,
	});

	console.log("[sendConceroMessage]: Message sent: ", decodedEvent);

	return {
		txHash,
		blockNumber: txReceipt.blockNumber,
		internalMessageConfig: foundMessageSentLog.topics[1],
		messageId: foundMessageSentLog.topics[2],
		dstChainData: decodedEvent.args.dstChainData,
		message: decodedEvent.args.message,
	};
}
