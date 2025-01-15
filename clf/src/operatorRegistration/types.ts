import { Address } from "viem";
import { ChainType } from "./enums";

interface OperatorRegistrationArgs {
    chainTypes: ChainType[];
    operatorAddresses: Address[];
    operatorAddress: Address;
}

export { OperatorRegistrationArgs };
