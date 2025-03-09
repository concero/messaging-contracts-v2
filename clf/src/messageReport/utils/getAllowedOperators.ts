import { type Address, zeroAddress } from "viem";
import { Hash } from "viem";
import { PublicClient } from "viem/clients/createPublicClient";

import { config } from "../../common/config";
import { ChainType } from "../../common/enums";
import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { CONCERO_VERIFIER_CONTRACT_ABI } from "../constants/abis";
import { CONCERO_VERIFIER_CONTRACT_ADDRESS } from "../constants/conceroRouters";
import { getMessageCohortId, getOperatorCohortId } from "./utils";

/**
 * Gets all allowed operators for a given message ID based on cohort assignment
 * @param client - Viem public client instance
 * @param chainType - Type of chain (e.g., EVM)
 * @param messageId - Message identifier
 * @returns Array of operator addresses allowed for the message
 */
export async function getAllowedOperators(
	client: PublicClient,
	chainType: ChainType,
	messageId: Hash,
): Promise<Address[]> {
	try {
		const cohortsCount = await getCohortsCount(client);
		const messageCohort = getMessageCohortId(messageId, cohortsCount);

		const registeredOperators = await getRegisteredOperators(client, chainType);

		// Filter operators that belong to the same cohort as the message
		const allowedOperators = registeredOperators.filter(
			operator => getOperatorCohortId(operator, cohortsCount) === messageCohort,
		);

		if (!allowedOperators.length) {
			handleError(ErrorType.NO_ALLOWED_OPERATORS);
		}

		return allowedOperators;
	} catch (error) {
		// handleError(ErrorType.OPERATOR_SELECTION_FAILED);
		throw error;
	}
}

async function getCohortsCount(client: PublicClient): Promise<number> {
	const cohortsCount = (await client.readContract({
		abi: CONCERO_VERIFIER_CONTRACT_ABI,
		address: CONCERO_VERIFIER_CONTRACT_ADDRESS,
		functionName: "getCohortsCount",
		args: [],
	})) as number;

	if (cohortsCount <= 0) {
		handleError(ErrorType.INVALID_COHORTS_COUNT);
	}

	return cohortsCount;
}

async function getRegisteredOperators(client: PublicClient, chainType: ChainType): Promise<Address[]> {
	//@dev TODO: remove it!
	if (config.isDevelopment) {
		return [zeroAddress];
	}

	const registeredOperators = (await client.readContract({
		abi: CONCERO_VERIFIER_CONTRACT_ABI,
		address: CONCERO_VERIFIER_CONTRACT_ADDRESS,
		functionName: "getRegisteredOperators",
		args: [chainType],
	})) as Address[];

	if (!registeredOperators.length) {
		handleError(ErrorType.NO_REGISTERED_OPERATORS);
	}

	return registeredOperators;
}
