import { encodeAbiParameters, keccak256 } from "viem";
import { ClientMessageRequest } from "../constants/abis";
import { ErrorType } from "../constants/errorTypes";
import { handleError } from "./errorHandler";

export async function verifyMessageHash(
    messageId: string,
    messageConfig: string,
    dstChainData: string,
    message: string,
    expectedHashSum: string,
) {
    const messageBytes = encodeAbiParameters(
        ["bytes32", ClientMessageRequest],
        [
            messageId,
            {
                messageConfig: BigInt(messageConfig),
                dstChainData,
                message: keccak256(message),
            },
        ],
    );

    const recomputedMessageHashSum = keccak256(messageBytes);
    if (recomputedMessageHashSum !== expectedHashSum) {
        handleError(ErrorType.INVALID_HASHSUM);
    }

    return recomputedMessageHashSum;
}
