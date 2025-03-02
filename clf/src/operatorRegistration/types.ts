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
	reportType: number; //                ─╮
	version: number; //                    │ Report Response Config
	// 10 bytes reserved for future use    │ Packed as a uint256
	requester: Address; //                ─╯

	chainTypes: ChainType[];
	actions: OperatorRegistrationAction[];
	operatorAddresses: string[];
}

export { OperatorRegistrationArgs, OperatorRegistrationResult, OperatorRegistrationAction };
