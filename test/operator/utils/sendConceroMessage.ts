import { PublicClient, WalletClient, decodeEventLog, parseUnits } from "viem";
import { privateKeyToAccount } from "viem/accounts";

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
		address: clientAddress,
		abi: exampleClientAbi,
		functionName: "sendConceroMessage",
		args: [clientAddress],
		account: privateKeyToAccount(`0x${process.env.LOCALHOST_DEPLOYER_PRIVATE_KEY}`),
		value: parseUnits("0.001", 18),
	});

	const txReceipt = await publicClient.getTransactionReceipt({ hash: txHash });

	const foundMessageSentLog = txReceipt.logs.find(log => {
		try {
			const decoded = decodeEventLog({
				abi: globalConfig.ABI.CONCERO_ROUTER,
				data: log.data,
				topics: log.topics,
				strict: true,
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

	console.log("sent Concero message", {
		txHash,
		blockNumber: txReceipt.blockNumber,
		internalMessageConfig: foundMessageSentLog.topics[1],
		messageId: foundMessageSentLog.topics[2],
		eventArgs: decodedEvent.args,
	});

	return {
		txHash,
		blockNumber: txReceipt.blockNumber,
		internalMessageConfig: foundMessageSentLog.topics[1],
		messageId: foundMessageSentLog.topics[2],
		dstChainData: decodedEvent.args.dstChainData,
		message: decodedEvent.args.message,
	};
}
