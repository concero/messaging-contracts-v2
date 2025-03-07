import { decodeEventLog, parseUnits } from "viem";

import { task } from "hardhat/config";

import { conceroNetworks, networkEnvKeys } from "../constants";
import { getEnvVar, getFallbackClients, log } from "../utils";

/**
 * Sends a Concero message using the ConceroClientExample contract
 */
task("send-concero-message", "Send a test Concero message through the client")
	.addOptionalParam("value", "Amount of native token to send with the message", "0.001")
	.addOptionalParam("client", "Address of the ConceroClientExample contract")
	.addOptionalParam("receiver", "Address of the receiver contract")
	.setAction(async (taskArgs, hre) => {
		// Get the client address from args or env variables
		const clientAddress =
			taskArgs.client ||
			getEnvVar(`CONCERO_CLIENT_EXAMPLE_${networkEnvKeys[hre.network.name]}`);
		if (!clientAddress) {
			throw new Error("Client address not provided and not found in environment variables");
		}

		const conceroNetwork = conceroNetworks[hre.network.name];
		const { walletClient, publicClient } = getFallbackClients(conceroNetwork);

		log(`Sending Concero message from client ${clientAddress}`, "send-concero-message");
		log(`Using network: ${hre.network.name}`, "send-concero-message");

		const { abi: exampleClientAbi } = await import(
			"../artifacts/contracts/ConceroClient/ConceroClientExample.sol/ConceroClientExample.json"
		);

		const { abi: CONCERO_ROUTER_ABI } = await import(
			"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
		);

		const value = parseUnits(taskArgs.value, 18);
		log(`Sending with value: ${taskArgs.value} ETH`, "send-concero-message");

		try {
			const txHash = await walletClient.writeContract({
				address: clientAddress,
				abi: exampleClientAbi,
				functionName: "sendConceroMessage",
				args: [taskArgs.receiver],
				account: walletClient.account,
				value,
			});

			log(`Transaction submitted: ${txHash}`, "send-concero-message");
			log("Waiting for transaction receipt...", "send-concero-message");

			const txReceipt = await publicClient.getTransactionReceipt({ hash: txHash });

			const foundMessageSentLog = txReceipt.logs.find(log => {
				try {
					const decoded = decodeEventLog({
						abi: CONCERO_ROUTER_ABI,
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
				log("ConceroMessageSent event not found in logs", "send-concero-message");
				return;
			}

			const decodedEvent = decodeEventLog({
				abi: CONCERO_ROUTER_ABI,
				data: foundMessageSentLog.data,
				topics: foundMessageSentLog.topics,
			});

			log("Message sent successfully!", "send-concero-message");
			log(`Message ID: ${foundMessageSentLog.topics[2]}`, "send-concero-message");
			log(`Block Number: ${txReceipt.blockNumber}`, "send-concero-message");
			log(`Transaction hash: ${txHash}`, "send-concero-message");

			return {
				txHash,
				blockNumber: txReceipt.blockNumber,
				internalMessageConfig: foundMessageSentLog.topics[1],
				messageId: foundMessageSentLog.topics[2],
				dstChainData: decodedEvent.args.dstChainData,
				message: decodedEvent.args.message,
			};
		} catch (error) {
			log(`Error sending Concero message: ${error.message}`, "send-concero-message", "error");
			throw error;
		}
	});
