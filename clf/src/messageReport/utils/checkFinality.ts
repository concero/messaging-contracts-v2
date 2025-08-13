import { config } from "../../common/config";

import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { ChainSelector } from "../../common/types";
import { getRpcConfigForChain } from "../../common/viemClient";

export function checkFinality(chainSelector: ChainSelector, submittedBlockNumber: bigint, currentBlockNumber: bigint) {
	const configFinalityConfirmations = getRpcConfigForChain(chainSelector).finalityConfirmations;
	const finalityConfirmations =
		configFinalityConfirmations > 0 ? configFinalityConfirmations : config.defaultFinalityConfirmations;
	const finalityConfirmationBlock = submittedBlockNumber + BigInt(finalityConfirmations);

	if (currentBlockNumber < finalityConfirmationBlock) {
		handleError(ErrorType.FINALITY_NOT_REACHED);
	}
}
