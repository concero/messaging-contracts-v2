import { createPublicClient } from "viem";
import { ErrorType } from "../constants/errorTypes";
import { handleError } from "../../common/errorHandler";

async function fetchConceroMessage(
    client: ReturnType<typeof createPublicClient>,
    routerAddress: string,
    messageId: string,
    blockNumber: bigint,
) {
    const logs = await client.getLogs({
        address: routerAddress,
        topics: [null, messageId],
        fromBlock: blockNumber - 10n,
        toBlock: blockNumber,
    });
    if (!logs.length) handleError(ErrorType.EVENT_NOT_FOUND);
    return logs[0];
}

export { fetchConceroMessage };
