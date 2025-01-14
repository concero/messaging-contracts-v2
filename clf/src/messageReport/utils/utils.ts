import { type Address } from "../../../../typechain-types";
import { ErrorType } from "../constants/errorTypes";
import { handleError } from "./errorHandler";

function getRandomRpc(rpcs: { url: string; chainId: string }[]) {
    return rpcs[Math.floor(Math.random() * rpcs.length)];
}

function sleep(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function getOperatorCohortId(operator: Address, cohortsCount: number): number {
    return parseInt(operator.slice(2), 16) % cohortsCount;
}

function getMessageCohortId(messageId: string, cohortsCount: number): number {
    return parseInt(messageId.slice(2), 16) % cohortsCount;
}

function pick<T>(array: T[], n: number): T[] {
    if (n > array.length) {
        handleError(ErrorType.INVALID_OPERATOR_COUNT);
    }
    const shuffled = [...array];

    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }

    return shuffled.slice(0, n);
}

export { getRandomRpc, sleep, getMessageCohortId, getOperatorCohortId, pick };
