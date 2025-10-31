import { Log, PublicClient, Address } from "viem";
import { ConceroMessageLogParams, conceroMessageSentEventName } from "../constants";
import { CustomError, ErrorTypes } from "../error";

export class Fetcher {
    static async fetchConceroMessage(
        client: PublicClient,
        routerAddress: Address,
        messageId: string,
        blockNumber: bigint,
    ): Log {
        const logs = await client.getLogs({
            event: { type: "event", inputs: ConceroMessageLogParams, name: conceroMessageSentEventName },
            address: routerAddress,
            fromBlock: blockNumber - 10n,
            toBlock: blockNumber,
        });

        if (!logs.length) {
            throw new CustomError(ErrorTypes.Type.EVENT_NOT_FOUND);
        }

        const conceroMessageSentLog = logs.find(log => log.topics[1]?.toLowerCase() === messageId.toLowerCase());

        if (!conceroMessageSentLog) {
            throw new CustomError(ErrorTypes.Type.EVENT_NOT_FOUND);
        }

        return conceroMessageSentLog;
    }

}