import { globalConfig } from "@concero/v2-operators/src/constants";
import { Address, Hash, decodeEventLog, encodeAbiParameters, keccak256 } from "viem";

import { getEnvVar } from "../../../utils";
import { ExtendedTestClient } from "../../../utils/getViemClients";
import { getMessageCLFReportResponse } from "../getMessageCLFReportResponse";

function createSrcChainData(sender: Address, blockNumber: number) {
	return encodeAbiParameters(
		[
			{
				type: "tuple",
				components: [
					{ type: "uint256", name: "blockNumber" },
					{ type: "address", name: "sender" },
				],
			},
		],
		[{ sender, blockNumber: BigInt(blockNumber) }],
	);
}

export async function handleMessageReportRequestWithFinalization(
	testClient: ExtendedTestClient,
	txHash: Hash,
) {
	const receipt = await testClient.getTransactionReceipt({ hash: txHash });

	let messageReportLog;
	let requestSentLog;

	for (const log of receipt.logs) {
		try {
			const decoded = decodeEventLog({
				abi: globalConfig.ABI.CONCERO_VERIFIER,
				data: log.data,
				topics: log.topics,
				strict: true,
			});

			if (decoded.eventName === "MessageReportRequested") {
				messageReportLog = { log, decoded };
			} else if (decoded.eventName === "RequestSent") {
				requestSentLog = { log, decoded };
			}
		} catch {}
	}

	if (!messageReportLog) throw new Error("MessageReportRequested event not found");

	if (!requestSentLog) throw new Error("RequestSent event not found");

	const latestBlockNumber = await testClient.getBlockNumber();
	const logs = await testClient.getLogs({
		fromBlock: BigInt(Math.max(0, Number(latestBlockNumber - 10000n))),
		toBlock: latestBlockNumber,
	});

	let messageLog;
	let messageLogBlockNumber;
	for (const log of logs) {
		try {
			const decoded = decodeEventLog({
				abi: globalConfig.ABI.CONCERO_ROUTER,
				data: log.data,
				topics: log.topics,
			});

			if (
				decoded.eventName === "ConceroMessageSent" &&
				decoded.args.messageId.toLowerCase() ===
					messageReportLog.log.topics[1]?.toLocaleLowerCase()
			) {
				messageLog = decoded;
				messageLogBlockNumber = log.blockNumber;
				break;
			}
		} catch {
			continue;
		}
	}

	const result = await getMessageCLFReportResponse({
		messageId: messageReportLog.decoded.args.messageId,
		messageHash: keccak256(messageLog.args.message),
		srcChainSelector: testClient.chain?.id.toString(),
		srcChainData: createSrcChainData(messageLog.args.sender, messageLogBlockNumber),
		operatorAddresses: getEnvVar("OPERATOR_ADDRESS"),
	});

	const { capturedTerminalOutput } = result;

	if (capturedTerminalOutput) {
		const errorCode = capturedTerminalOutput.match(/"message":"(\d+)"/)?.[1];
		throw new Error(errorCode);
	}

	return result;
}
