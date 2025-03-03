import { encodeAbiParameters, keccak256, parseAbiParameters } from "viem";
import { ErrorType } from "../../common/errorType";
import { handleError } from "../../common/errorHandler";
import { HexString } from "ethers/lib.commonjs/utils/data";
import { ClientMessageRequestBase } from "../constants/abis";

export function verifyMessageHash(
    messageId: HexString,
    messageConfig: HexString,
    dstChainData: HexString,
    message: HexString,
    expectedHashSum: HexString,
) {
    const messageBytes = encodeAbiParameters(
        [{ name: "messageId", type: "bytes32" }, ...parseAbiParameters(ClientMessageRequestBase)],
        [messageId, messageConfig, dstChainData, keccak256(message)],
    );

    const recomputedMessageHashSum = keccak256(messageBytes);
    if (recomputedMessageHashSum !== expectedHashSum) {
        handleError(ErrorType.INVALID_HASHSUM);
    }

    return recomputedMessageHashSum;
}
