import { Address } from "viem";
import { ErrorType } from "../constants/errorTypes";
import { handleError } from "../../common/errorHandler";

export async function verifyOperatorStake(operatorAddress: Address): Promise<number> {
    try {
        const stakeAmount = Math.random() > 0.5 ? 100 : 0;

        if (stakeAmount <= 0) {
            handleError(ErrorType.INVALID_OPERATOR_STAKE);
        }

        return stakeAmount;
    } catch (error) {
        handleError(ErrorType.INVALID_OPERATOR_STAKE);
    }
}
