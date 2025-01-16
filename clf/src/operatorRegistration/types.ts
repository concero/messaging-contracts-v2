import { Address } from "viem";
import { ChainType } from "../common/enums";

interface OperatorRegistrationArgs {
    chainTypes: ChainType[];
    operatorAddresses: Address[];
    operatorAddress: Address;
}

interface OperatorRegistrationResult {
    version: number;
    reportType: number;
    operator: Address;
    chainTypes: ChainType[];
    operatorAddresses: string[];
}

export { OperatorRegistrationArgs, OperatorRegistrationResult };
