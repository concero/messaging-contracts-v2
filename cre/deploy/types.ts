import { type Address, type Hash, type Hex } from "viem";

export type GlobalContext = {}

export enum ResultType {
    UNKNOWN = 0,
    MESSAGE = 1,
    OPERATOR_REGISTRATION = 2,
}

export type EvmSrcChainData = {
    sender: Address;
    blockNumber: string;
}

export type DecodedArgs = {
    messageId: Hash;
    messageHashSum: Hash;
    srcChainSelector: number;
    srcChainData: EvmSrcChainData;
    operatorAddress: Address;
}

export type MessageReportResult = {
    // resultConfig
    payloadVersion: number;
    resultType: number;
    requester: Address;
    // payload
    messageId: Hash;
    messageHashSum: Hash;
    messageSender: Hash;
    srcChainSelector: number;
    dstChainSelector: number;
    srcBlockNumber: bigint;
    dstChainData: string;
    allowedOperators: string[];
}

export type DecodedLog = {
    version: Hex;
    shouldFinaliseSrc: Hex;
    dstChainSelector: Hex;
    dstChainData: Hex;
    sender: Hex;
    message: Hex;
}