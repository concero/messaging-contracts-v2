import { Hex, keccak256 } from "viem";
import { ErrorType } from "../../common/errorType";
import { handleError } from "../../common/errorHandler";
import { HexString } from "ethers/lib.commonjs/utils/data";

export function verifyMessageHash(message: HexString, expectedHashSum: HexString) {
    if (keccak256(message as Hex).toLowerCase() !== expectedHashSum.toLowerCase()) {
        handleError(ErrorType.INVALID_HASHSUM);
    }
}
