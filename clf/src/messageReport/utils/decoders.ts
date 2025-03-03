import { EvmSrcChainData } from "../types";
import { decodeAbiParameters } from "viem";
import { NonIndexedConceroMessageParams, EvmSrcChainDataParams } from "../constants/abis";
import { ErrorType } from "../../common/errorType";
import { handleError } from "../../common/errorHandler";
import { HexString } from "ethers/lib.commonjs/utils/data";

type Log = {
    topics: string[];
    data: string;
};

export function decodeConceroMessageLog(log: Log): {
    messageId: HexString;
    internalMessageConfig: HexString;
    dstChainData: HexString;
    message: HexString;
} {
    try {
        const messageId = log.topics[1];
        const internalMessageConfig = log.topics[2];
        const [dstChainData, message] = decodeAbiParameters(NonIndexedConceroMessageParams, log.data);

        return {
            messageId,
            internalMessageConfig,
            dstChainData,
            message,
        };
    } catch (error) {
        handleError(ErrorType.INVALID_DATA);
    }
}

export function decodeEvmSrcChainData(encodedData: string): EvmSrcChainData {
    if (!encodedData || typeof encodedData !== "string") {
        handleError(ErrorType.INVALID_DATA);
    }

    try {
        const [sender, blockNumber] = decodeAbiParameters(EvmSrcChainDataParams, encodedData);

        return {
            sender,
            blockNumber: blockNumber.toString(),
        };
    } catch (error) {
        handleError(ErrorType.INVALID_DATA);
    }
}
