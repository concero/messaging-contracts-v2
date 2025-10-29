import { type Address } from "../../../../typechain-types";
import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";

export function getRandomRpc(rpcs: { url: string; chainId: string }[]) {
	return rpcs[Math.floor(Math.random() * rpcs.length)];
}

export function sleep(ms: number) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

export function getOperatorCohortId(operator: Address, cohortsCount: number): number {
	return parseInt(operator.slice(2), 16) % cohortsCount;
}

export function getMessageCohortId(messageId: string, cohortsCount: number): number {
	return parseInt(messageId.slice(2), 16) % cohortsCount;
}

export function pick<T>(array: T[], n: number): T[] {
	if (n > array.length) {
		handleError(ErrorType.INVALID_OPERATOR_COUNT);
	}

	// @dev TODO: is it correct?
	const shuffled = [...array];

	for (let i = shuffled.length - 1; i > 0; i--) {
		const j = Math.floor(Math.random() * (i + 1));
		[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
	}

	return shuffled.slice(0, n);
}
