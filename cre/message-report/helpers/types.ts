import { type Hash } from "viem";

export type GlobalContext = {}

export type DecodedArgs = {
    messageId: Hash;
    srcChainSelector: number;
    blockNumber: string;
}