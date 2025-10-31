import { config } from "../config";

import { type Address, Hash } from "viem";
import { PublicClient } from "viem/clients/createPublicClient";

import { ChainType } from "../types";
import { CustomError, ErrorTypes } from "../error";
import { getPublicClient } from "../client";
import { CONCERO_VERIFIER_CONTRACT_ABI, CONCERO_VERIFIER_CONTRACT_ADDRESS } from "../constants";
import { getMessageCohortId, getOperatorCohortId } from "./utils";

/**
 * Gets all allowed operators for a given message ID based on cohort assignment
 * @param chainType - Type of chain (e.g., EVM)
 * @param messageId - Message identifier
 * @returns Array of operator addresses allowed for the message
 */
export async function getAllowedOperators(chainType: ChainType, messageId: Hash): Promise<Address[]> {
	try {
		const client = getPublicClient(config.verifierChainSelector);
		const [cohortsCount, registeredOperators] = await Promise.all([
			getCohortsCount(client),
			getRegisteredOperators(client, chainType),
		]);

		const messageCohort = getMessageCohortId(messageId, cohortsCount);

		// Filter operators that belong to the same cohort as the message
		const allowedOperators = registeredOperators.filter(
			operator => getOperatorCohortId(operator, cohortsCount) === messageCohort,
		);

		if (!allowedOperators.length) {
            throw new CustomError(ErrorTypes.Type.NO_ALLOWED_OPERATORS);
		}

		return allowedOperators;
	} catch (error) {
        throw new CustomError(ErrorTypes.Type.OPERATOR_SELECTION_FAILED);
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
        throw new CustomError(ErrorTypes.Type.INVALID_COHORTS_COUNT);
	}

	return cohortsCount;
}

async function getRegisteredOperators(client: PublicClient, chainType: ChainType): Promise<Address[]> {
	const registeredOperators = (await client.readContract({
		abi: CONCERO_VERIFIER_CONTRACT_ABI,
		address: CONCERO_VERIFIER_CONTRACT_ADDRESS,
		functionName: "getRegisteredOperators",
		args: [chainType],
	})) as Address[];

	if (!registeredOperators.length) {
        throw new CustomError(ErrorTypes.Type.NO_REGISTERED_OPERATORS);
	}

	return registeredOperators;
}
