import { EvmSrcChainData } from "../types";
import { decodeAbiParameters } from "viem";
import { NonIndexedConceroMessageParams, EvmSrcChainDataParams } from "../constants/abis";
import { ErrorType } from "../../common/errorType";
import { handleError } from "../../common/errorHandler";

type Log = {
    topics: string[];
    data: string;
};

function decodeConceroMessageLog(log: Log): {
    messageId: string;
    internalMessageConfig: BigInt;
    dstChainData: string;
    message: string;
} {
    try {
        const messageId = log.topics[1];
        const internalMessageConfig = BigInt(log.topics[2]);
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

function decodeEvmSrcChainData(encodedData: string): EvmSrcChainData {
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

export { decodeEvmSrcChainData, decodeConceroMessageLog };
