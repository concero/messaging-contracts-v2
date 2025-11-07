import {type Address, type Log, type PublicClient} from "viem";
import {Runtime} from "@chainlink/cre-sdk";

import {DomainError, ErrorCode, GlobalContext, Utility} from "../helpers";
import {ConceroMessageLogParams, conceroMessageSentEventName} from "../abi";

const LOG_TAG = 'fetchLogByMessageId'

export async function fetchLogByMessageId(
    runtime: Runtime<GlobalContext>,
    client: PublicClient,
    address: Address,
    messageId: string,
    blockNumber: bigint,
): Promise<Log> {
    const fromBlock = blockNumber - 10n;
    const toBlock = blockNumber;

    runtime.log(`${LOG_TAG} Fetching ${JSON.stringify({ address, messageId, fromBlock: String(fromBlock), toBlock: String(toBlock) })}`);
    let logs: Log[] = [];

    try {
        logs = await client.getLogs({
            event: {
                type: "event",
                inputs: ConceroMessageLogParams,
                name: conceroMessageSentEventName,
            },
            address,
            fromBlock,
            toBlock
        })
        runtime.log(`${LOG_TAG} Fetched successfully ${Utility.safeJSONStringify({ logs })})`);
    } catch (e) {
        runtime.log(`${LOG_TAG} Fetching failed`);
        throw e;
    }

    if (!logs.length) {
        runtime.log(`${LOG_TAG} Logs are empty`);
        throw new DomainError(ErrorCode.EVENT_NOT_FOUND, 'Logs are empty');
    }

    const log = logs.find(
        (log) => {
            const logMessageId = log?.topics?.[1]?.toLowerCase();
            return logMessageId === messageId.toLowerCase();
        }
    );

    if (!log) {
        runtime.log(`${LOG_TAG} Log not found`);
        throw new DomainError(ErrorCode.EVENT_NOT_FOUND, '');
    }

    return log;
}