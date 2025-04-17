import { Address } from "viem";

import { ChainType } from "../common/enums";

enum OperatorRegistrationAction {
	DEREGISTER = 0,
	REGISTER = 1,
}
interface OperatorRegistrationArgs {
	chainTypes: ChainType[];
	actions: OperatorRegistrationAction[];
	operatorAddresses: Address[];
	requester: Address;
}

interface OperatorRegistrationResult {
	// resultConfig
	resultType: number;
	payloadVersion: number;
	requester: Address;
	// payload
	chainTypes: ChainType[];
	actions: OperatorRegistrationAction[];
	operatorAddresses: string[];
}

export { OperatorRegistrationArgs, OperatorRegistrationResult, OperatorRegistrationAction };
