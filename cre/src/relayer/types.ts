import { Address } from "viem";

import { ChainType } from "../types";

export namespace Relayer {
    export namespace Registration {
        export enum Action {
            DEREGISTER = 0,
            REGISTER = 1,
        }

        export type Args = {
            chainTypes: ChainType[];
            actions: Action[];
            operatorAddresses: Address[];
            requester: Address;
        }
        export type Result = {
            resultType: number;
            payloadVersion: number;
            requester: Address;
            // payload
            chainTypes: ChainType[];
            actions: Action[];
            operatorAddresses: string[];
        }
    }
}

