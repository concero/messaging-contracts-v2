import { DecodedMessageSentReceipt, DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

export const validateValidatorLib = (logParsedReceipt: DecodedMessageSentReceipt): void => {
	const srcChain = ChainsManager.getOptionsBySelector(logParsedReceipt.srcChainSelector);

	if (
		!srcChain.deployments.validatorLib ||
		!logParsedReceipt.validatorLibs.includes(srcChain.deployments.validatorLib)
	) {
		throw new DomainError(ErrorCode.INVALID_VALIDATOR, "ValidatorLib is not valid");
	}
};
