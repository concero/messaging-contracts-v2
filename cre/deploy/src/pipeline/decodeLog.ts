import { decodeAbiParameters, type Hex, type Log } from "viem";

import type { DecodedLog } from "../types";
import { DomainError, ErrorCode } from "../error";
import { NonIndexedConceroMessageParams } from "../constants";

export function decodeMessageLog(log: Log): DecodedLog {
    try {
        const [version, shouldFinaliseSrc, dstChainSelector, dstChainData, sender, message] = decodeAbiParameters(
            NonIndexedConceroMessageParams,
            log.data as Hex,
        );

        return {
            version,
            shouldFinaliseSrc,
            dstChainSelector,
            dstChainData,
            sender,
            message,
        } as DecodedLog;
    } catch (error) {
        throw new DomainError(ErrorCode.INVALID_DATA);
    }
}
