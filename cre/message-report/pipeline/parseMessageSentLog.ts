import { Hex, decodeEventLog } from "viem";

import { ConceroMessageSentEvent } from "../abi";
import { DecodedMessageSentReceipt, DomainError, ErrorCode, MessageSentLogData } from "../helpers";
import { MessagingCodec } from "./codec";
import { IFetchLogsResult } from "./fetchLogsByMessageIds";

export interface IParsedLog {
	blockNumber: bigint;
	transactionHash: Hex;
	data: MessageSentLogData;
	receipt: DecodedMessageSentReceipt;
	rawMessageReceipt: Hex;
}

export const parseMessageSentLog = (res: IFetchLogsResult): IParsedLog => {
	try {
		const decodedLog = decodeEventLog({
			abi: [ConceroMessageSentEvent.eventAbi],
			topics: res.log.topics,
			data: res.log.data,
			strict: true,
			eventName: ConceroMessageSentEvent.name,
		});
		const data = decodedLog.args as unknown as MessageSentLogData;

		const receipt = MessagingCodec.decodeReceipt(data.messageReceipt);
		return {
			blockNumber: BigInt(res.log.blockNumber!),
			transactionHash: res.log.transactionHash!,
			data,
			receipt,
			rawMessageReceipt: data.messageReceipt,
		};
	} catch (e) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, e?.toString());
	}
};
