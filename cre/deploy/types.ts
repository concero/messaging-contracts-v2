import { type Hash } from "viem";

export type GlobalContext = {}

export enum ResultType {
    UNKNOWN = 0,
    MESSAGE = 1,
    OPERATOR_REGISTRATION = 2,
}

export type DecodedArgs = {
    messageId: Hash;
    srcChainSelector: number;
    blockNumber: string;
}