import { HexString } from "ethers/lib.commonjs/utils/data";

import { decodeAbiParameters } from "viem";

import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { EvmSrcChainDataParams, NonIndexedConceroMessageParams } from "../constants/abis";
import { EvmSrcChainData } from "../types";

type Log = {
	topics: string[];
	data: string;
};

export function decodeConceroMessageLog(log: Log): {
	messageId: HexString;
	internalMessageConfig: HexString;
	dstChainData: HexString;
	message: HexString;
	sender: HexString;
} {
	try {
		const messageId = log.topics[2];
		const internalMessageConfig = log.topics[1];
		const [dstChainData, message, sender] = decodeAbiParameters(NonIndexedConceroMessageParams, log.data);

		return {
			messageId,
			internalMessageConfig,
			dstChainData,
			message,
			sender,
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
