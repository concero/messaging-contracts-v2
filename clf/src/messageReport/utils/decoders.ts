import { EvmSrcChainData } from "../types";
import { decodeAbiParameters } from "viem";
import { ClientMessageRequest } from "../constants/abis";
import { ErrorType } from "../constants/errorTypes";
import { handleError } from "../../common/errorHandler";

function decodeConceroMessageLog(conceroMessageLogData: string) {
    const [messageConfig, dstChainData, message] = decodeAbiParameters([ClientMessageRequest], conceroMessageLogData);

    return {
        messageConfig: BigInt(messageConfig), // uint256
        dstChainData, // bytes
        message, // bytes
    };
}

function decodeEvmSrcChainData(encodedData): EvmSrcChainData {
    if (!encodedData || typeof encodedData !== "string") {
        handleError(ErrorType.INVALID_DATA);
    }

    try {
        const abi = ["address", "uint256"];
        const [sender, blockNumber] = decodeAbiParameters(abi, encodedData);

        return {
            sender,
            blockNumber: blockNumber.toString(),
        };
    } catch (error) {
        handleError(ErrorType.INVALID_DATA);
    }
}

export { decodeEvmSrcChainData, decodeConceroMessageLog };
