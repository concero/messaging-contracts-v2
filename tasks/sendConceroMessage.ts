import { task } from "hardhat/config";

import { getNetworkEnvKey } from "@concero/contract-utils";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { decodeEventLog } from "viem";

import { conceroNetworks } from "../constants";
import { getEnvVar, getFallbackClients, log } from "../utils";

/**
 * Result of a successful message send operation
 */
type SendMessageResult = {
	txHash: `0x${string}`;
	blockNumber: bigint;
	internalMessageConfig: `0x${string}`;
	messageId: `0x${string}`;
	dstChainData: `0x${string}`;
	message: `0x${string}`;
};

/**
 * Parameters for sending a single Concero message
 */
interface SendMessageParams {
	clientAddress: string;
	dstChainClient: string;
	dstChainSelector: bigint;
	value: bigint;
	walletClient: any;
	publicClient: any;
	exampleClientAbi: any;
	routerAbi: any;
	logPrefix?: string;
}

const largePayload = "0x" + "1".repeat(90_000);

/**
 * Sends a single Concero message and returns the result
 */
async function sendSingleMessage({
	clientAddress,
	dstChainClient,
	dstChainSelector,
	value,
	walletClient,
	publicClient,
	exampleClientAbi,
	routerAbi,
	logPrefix = "send-concero-message",
}: SendMessageParams): Promise<SendMessageResult> {
	try {
		const txHash = await walletClient.writeContract({
			address: clientAddress,
			abi: [...exampleClientAbi, ...routerAbi],
			functionName: "sendConceroMessage",
			args: [dstChainClient, dstChainSelector, 0],
			account: walletClient.account,
			value,
		});

		log(`Transaction submitted: ${txHash}`, logPrefix);
		log("Waiting for transaction receipt...", logPrefix);

		const txReceipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

		const foundMessageSentLog = txReceipt.logs.find(log => {
			try {
				const decoded = decodeEventLog({
					abi: routerAbi,
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
			log("ConceroMessageSent event not found in logs", logPrefix);
			throw new Error("ConceroMessageSent event not found in logs");
		}

		const decodedEvent = decodeEventLog({
			abi: routerAbi,
			data: foundMessageSentLog.data,
			topics: foundMessageSentLog.topics,
		});

		log("Message sent successfully!", logPrefix);
		log(`Message ID: ${foundMessageSentLog.topics[2]}`, logPrefix);
		log(`Block Number: ${txReceipt.blockNumber}`, logPrefix);
		log(`Transaction hash: ${txHash}`, logPrefix);

		return {
			txHash,
			blockNumber: txReceipt.blockNumber,
			internalMessageConfig: foundMessageSentLog.topics[1],
			messageId: foundMessageSentLog.topics[2],
			dstChainData: decodedEvent.args.dstChainData,
			message: decodedEvent.args.message,
		};
	} catch (error) {
		log(`Error sending Concero message: ${error.message}`, logPrefix, "error");
		throw error;
	}
}

/**
 * Sends a Concero message using the ConceroClientExample contract
 */
task("send-concero-message", "Send a test Concero message through the client")
	.addOptionalParam("client", "Address of the ConceroClientExample contract")
	.addOptionalParam("receiver", "Address of the receiver contract")
	.addOptionalParam("concurrency", "Number of messages to send concurrently", "1")
	.addParam("dstnetwork", "Destination chain network")
	.setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
		// Get the client address from args or env variables
		const clientAddress =
			taskArgs.client ||
			getEnvVar(`CONCERO_CLIENT_EXAMPLE_${getNetworkEnvKey(hre.network.name)}`);
		if (!clientAddress) {
			throw new Error("Client address not provided and not found in environment variables");
		}

		const conceroNetwork = conceroNetworks[hre.network.name];
		if (!conceroNetwork) {
			throw new Error(`Source network '${hre.network.name}' not found in conceroNetworks`);
		}

		const { walletClient, publicClient } = getFallbackClients(conceroNetwork);

		log(`Using network: ${hre.network.name}`, "send-concero-message");
		log(`Client address: ${clientAddress}`, "send-concero-message");

		const { abi: exampleClientAbi } = await import(
			"../artifacts/contracts/examples/ConceroClientExample.sol/ConceroClientExample.json"
		);
		const { abi: CONCERO_ROUTER_ABI } = await import(
			"../artifacts/contracts/ConceroRouter/ConceroRouter.sol/ConceroRouter.json"
		);

		const dstNetwork = conceroNetworks[taskArgs.dstnetwork];
		if (!dstNetwork) {
			throw new Error(
				`Destination network '${taskArgs.dstnetwork}' not found in conceroNetworks`,
			);
		}
		const dstChainSelector = dstNetwork.chainSelector;
		const dstChainClient = getEnvVar(
			`CONCERO_CLIENT_EXAMPLE_${getNetworkEnvKey(dstNetwork.name)}`,
		);
		if (!dstChainClient) {
			throw new Error(
				`Destination chain client address not found for network: ${dstNetwork.name}`,
			);
		}

		const srcConceroRouter = getEnvVar(
			`CONCERO_ROUTER_PROXY_${getNetworkEnvKey(hre.network.name)}`,
		);
		const dstChainData = {
			receiver: dstChainClient,
			gasLimit: 100000,
		};

		const value = (await publicClient.readContract({
			address: clientAddress,
			abi: [...exampleClientAbi, ...CONCERO_ROUTER_ABI],
			functionName: "getMessageFee",
			args: [dstChainData.receiver, Number(dstChainSelector)],
		})) as bigint;

		log(`Sending with value: ${value} ETH`, "send-concero-message");

		const concurrency = parseInt(taskArgs.concurrency);

		if (isNaN(concurrency) || concurrency <= 0) {
			throw new Error("Concurrency must be a positive number");
		}

		// Common parameters for all message sends
		const messageParams: Omit<SendMessageParams, "logPrefix"> = {
			clientAddress,
			dstChainClient,
			dstChainSelector,
			value,
			walletClient,
			publicClient,
			exampleClientAbi,
			routerAbi: CONCERO_ROUTER_ABI,
		};

		if (concurrency === 1) {
			log(`Sending a single Concero message`, "send-concero-message");

			return await sendSingleMessage({
				...messageParams,
				logPrefix: "send-concero-message",
			});
		} else {
			log(`Sending ${concurrency} Concero messages concurrently`, "send-concero-message");

			const messagePromises = Array(concurrency)
				.fill(null)
				.map((_, index) => {
					return sendSingleMessage({
						...messageParams,
						logPrefix: `send-concero-message-${index + 1}`,
					}).catch(error => {
						log(
							`Message ${index + 1} failed: ${error.message}`,
							"send-concero-message",
							"error",
						);
						return null;
					});
				});

			const results = await Promise.all(messagePromises);
			const successfulResults = results.filter(Boolean) as SendMessageResult[];
			log(
				`Successfully sent ${successfulResults.length}/${concurrency} concurrent messages`,
				"send-concero-message",
			);

			return successfulResults;
		}
	});

export default {};
