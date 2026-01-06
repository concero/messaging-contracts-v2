import { Address } from "viem";

import { DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";

export const validateValidatorLib = (
	srcChainSelector: number,
	logValidatorLibs: Address[],
): void => {
	const srcChain = ChainsManager.getOptionsBySelector(srcChainSelector);

	if (
		!srcChain.deployments.validatorLib ||
		!logValidatorLibs
			.map(i => i.toLowerCase())
			.includes(srcChain.deployments.validatorLib.toLowerCase())
	) {
		throw new DomainError(ErrorCode.INVALID_VALIDATOR, "ValidatorLib is not valid");
	}
};
