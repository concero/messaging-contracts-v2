import { DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";
import { MessagingCodec } from "./codec";
import { fetchLogByMessageId } from "./fetchLogByMessageId";

export const validateValidatorLib = (
	log: Awaited<ReturnType<typeof fetchLogByMessageId>>,
): void => {
	const parsedReceipt = MessagingCodec.decodeReceipt(log.data.messageReceipt);
	const srcChain = ChainsManager.getOptionsBySelector(parsedReceipt.srcChainSelector);

	if (
		!srcChain.deployments.validatorLib ||
		!parsedReceipt.validatorLibs.includes(srcChain.deployments.validatorLib)
	) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "ValidatorLib is not valid");
	}
};
