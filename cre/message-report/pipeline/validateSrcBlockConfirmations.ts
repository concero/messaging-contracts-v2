import { maxUint64 } from "viem";

import { DecodedMessageSentReceipt, DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

export const validateSrcBlockConfirmations = (receipt: DecodedMessageSentReceipt) => {
	if (
		receipt.srcChainData.blockConfirmations === maxUint64 &&
		!ChainsManager.getOptionsBySelector(receipt.srcChainSelector).isFinalitySupported
	) {
		throw new DomainError(
			ErrorCode.FINALITY_NOT_SUPPORTED,
			`Finality is not supported for chain ${receipt.srcChainSelector}`,
		);
	}
};
