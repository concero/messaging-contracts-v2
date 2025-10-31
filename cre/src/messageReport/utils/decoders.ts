import { HexString } from "ethers/lib.commonjs/utils/data";
import { decodeAbiParameters } from "viem";

import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { EvmSrcChainDataParams, NonIndexedConceroMessageParams } from "../../constants/abis";
import { EvmSrcChainData } from "../types";

type Log = {
	topics: string[];
	data: string;
};

export function decodeConceroMessageLog(log: Log): {
	version: HexString;
	shouldFinaliseSrc: HexString;
	dstChainSelector: HexString;
	dstChainData: HexString;
	sender: HexString;
	message: HexString;
} {
	try {
		const [version, shouldFinaliseSrc, dstChainSelector, dstChainData, sender, message] = decodeAbiParameters(
			NonIndexedConceroMessageParams,
			log.data,
		);

		return {
			version,
			shouldFinaliseSrc,
			dstChainSelector,
			dstChainData,
			sender,
			message,
		};
	} catch (error) {
		handleError(ErrorType.INVALID_DATA);
	}
}

export function decodeEvmSrcChainData(encodedData: string): EvmSrcChainData {
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
