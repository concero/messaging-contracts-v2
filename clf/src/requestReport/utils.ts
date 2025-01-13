import { createPublicClient, decodeAbiParameters } from "viem";
import { ClientMessageRequest, ErrorType } from "./constants";
import { type Address } from "../../../typechain-types";

function getRandomRpc(rpcs: { url: string; chainId: string }[]) {
    return rpcs[Math.floor(Math.random() * rpcs.length)];
}

function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function getCohortId(operator: Address, cohortsCount: number): number {
    // Convert address to number and calculate modulo
    // slice(2) removes '0x' prefix, parseInt with base 16 converts hex to decimal
    return parseInt(operator.slice(2), 16) % cohortsCount;
}

function pick<T>(array: T[], n: number): T[] {
    if (n > array.length) {
        throw new Error(ErrorType.INVALID_OPERATOR_COUNT);
    }
    const shuffled = [...array];

    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    return shuffled.slice(0, n);
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

export { getRandomRpc, sleep, fetchConceroMessage, decodeConceroMessageLog, getCohortId, pick };
