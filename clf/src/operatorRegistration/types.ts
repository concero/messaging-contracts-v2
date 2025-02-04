import { Address } from "viem";
import { ChainType } from "../common/enums";

enum OperatorRegistrationAction {
    REGISTER = 0,
    DEREGISTER = 1,
}
interface OperatorRegistrationArgs {
    chainTypes: ChainType[];
    actions: OperatorRegistrationAction[];
    operatorAddresses: Address[];
    operatorAddress: Address;
}

interface OperatorRegistrationResult {
    version: number;
    reportType: number;
    operator: Address;
    chainTypes: ChainType[];
    actions: OperatorRegistrationAction[];
    operatorAddresses: string[];
}

export { OperatorRegistrationArgs, OperatorRegistrationResult, OperatorRegistrationAction };
