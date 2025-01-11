import { createPublicClient, decodeAbiParameters } from "viem";
import { ClientMessageRequest, ErrorType } from "./constants";

function getRandomRpc(rpcs: { url: string; chainId: string }[]) {
    return rpcs[Math.floor(Math.random() * rpcs.length)];
}

function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function decodeConceroMessageLog(conceroMessageLogData: string) {
    const [messageConfig, dstChainData, message] = decodeAbiParameters([ClientMessageRequest], conceroMessageLogData);

    return {
        messageConfig: BigInt(messageConfig), // uint256
        dstChainData, // bytes
        message, // bytes
    };
}

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
    if (!logs.length) throw new Error(ErrorType.EVENT_NOT_FOUND);
    return logs[0];
}

export { getRandomRpc, sleep, fetchConceroMessage, decodeConceroMessageLog };
