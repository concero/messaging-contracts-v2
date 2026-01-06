import { Hex, Log, decodeEventLog } from "viem";

import { ConceroMessageSentEvent } from "../abi";
import { DecodedMessageSentReceipt, DomainError, ErrorCode, MessageSentLogData } from "../helpers";
import { MessagingCodec } from "./codec";

export const parseMessageSentLog = (
	log: Log,
): {
	blockNumber: bigint;
	transactionHash: Hex;
	data: MessageSentLogData;
	receipt: DecodedMessageSentReceipt;
	rawMessageReceipt: Hex;
} => {
	try {
		const decodedLog = decodeEventLog({
			abi: [ConceroMessageSentEvent.eventAbi],
			topics: log.topics,
			data: log.data,
			strict: true,
			eventName: ConceroMessageSentEvent.name,
		});
		const data = decodedLog.args as unknown as MessageSentLogData;

		const receipt = MessagingCodec.decodeReceipt(data.messageReceipt);
		return {
			blockNumber: log.blockNumber!,
			transactionHash: log.transactionHash!,
			data,
			receipt,
			rawMessageReceipt: data.messageReceipt,
		};
	} catch (e) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, e?.toString());
	}
};
