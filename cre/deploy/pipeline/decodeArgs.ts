import { type Hex } from "viem";
import { decodeJson, HTTPPayload } from "@chainlink/cre-sdk";

import { DomainError, ErrorCode } from "../error";
import { type DecodedArgs } from "../types";

export function decodeArgs(payload: HTTPPayload): DecodedArgs {
    try {
        const data: Record<string, unknown> = decodeJson(payload.input);

        const messageId = data.messageId as Hex;
        const srcChainSelector = Number(data.srcChainSelector)
        const blockNumber = data.blockNumber as string

        return {
            srcChainSelector, 
            messageId,
            blockNumber,
        };
    } catch (e) {
        throw new DomainError(ErrorCode.INVALID_DATA);
    }
}
