import { HexString } from "ethers/lib.commonjs/utils/data";
import { Hex, keccak256 } from "viem";

import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";

export function verifyMessageHash(message: HexString, expectedHashSum: HexString) {
	if (keccak256(message as Hex).toLowerCase() !== expectedHashSum.toLowerCase()) {
		handleError(ErrorType.INVALID_HASHSUM);
	}
}
