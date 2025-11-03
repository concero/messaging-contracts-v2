import { type Address, type Log, type PublicClient } from "viem";

import { ConceroMessageLogParams, conceroMessageSentEventName } from "../constants";
import { DomainError, ErrorCode } from "../error";

export async function fetchLogByMessageId(
    client: PublicClient,
    routerAddress: Address,
    messageId: string,
    blockNumber: bigint,
): Promise<Log> {
    const logs = await client.getLogs({
        event: { type: "event", inputs: ConceroMessageLogParams, name: conceroMessageSentEventName },
        address: routerAddress,
        fromBlock: blockNumber - 10n,
        toBlock: blockNumber,
    });

    if (!logs.length) {
        throw new DomainError(ErrorCode.EVENT_NOT_FOUND);
    }

    const conceroMessageSentLog = logs.find(log => log.topics[1]?.toLowerCase() === messageId.toLowerCase());

    if (!conceroMessageSentLog) {
        throw new DomainError(ErrorCode.EVENT_NOT_FOUND);
    }

    return conceroMessageSentLog;
}