import { ChainType, CONCERO_VERIFIER_CONTRACT_ABI, CONCERO_VERIFIER_CONTRACT_ADDRESS, ErrorType } from "./constants";
import { type Address } from "viem";
import { PublicClient } from "viem/clients/createPublicClient";
import { getCohortId } from "./utils";

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
    messageId: string,
): Promise<Address[]> {
    try {
        const cohortsCount = (await client.readContract({
            abi: CONCERO_VERIFIER_CONTRACT_ABI,
            address: CONCERO_VERIFIER_CONTRACT_ADDRESS,
            functionName: "getCohortsCount",
            args: [chainType],
        })) as number;

        if (cohortsCount <= 0) {
            throw new Error(ErrorType.INVALID_COHORTS_COUNT);
        }

        const messageCohort = getCohortId(messageId as Address, cohortsCount);

        const registeredOperators = (await client.readContract({
            abi: CONCERO_VERIFIER_CONTRACT_ABI,
            address: CONCERO_VERIFIER_CONTRACT_ADDRESS,
            functionName: "getRegisteredOperators",
            args: [chainType],
        })) as Address[];

        if (!registeredOperators.length) {
            throw new Error(ErrorType.NO_REGISTERED_OPERATORS);
        }

        // Filter operators that belong to the same cohort as the message
        const allowedOperators = registeredOperators.filter(
            operator => getCohortId(operator, cohortsCount) === messageCohort,
        );

        if (!allowedOperators.length) {
            throw new Error(ErrorType.NO_ALLOWED_OPERATORS);
        }

        return allowedOperators;
    } catch (error) {
        // Log error for monitoring but throw a standardized error
        console.error("Error in getAllowedOperators:", error);
        throw error instanceof Error ? error : new Error(ErrorType.OPERATOR_SELECTION_FAILED);
    }
}
