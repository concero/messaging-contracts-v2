import { Address, createPublicClient } from "viem";
import { ErrorType } from "../../common/errorType";
import { handleError } from "../../common/errorHandler";

export async function fetchConceroMessage(
    client: ReturnType<typeof createPublicClient>,
    routerAddress: Address,
    messageId: string,
    blockNumber: bigint,
) {
    const logs = await client.getLogs({
        address: routerAddress,
        // @dev TODO: specify first topic to filter logs by event signature
        topics: [null, null, messageId],
        fromBlock: blockNumber - 10n,
        toBlock: blockNumber,
    });
    if (!logs.length) handleError(ErrorType.EVENT_NOT_FOUND);

    return logs[0];
}
