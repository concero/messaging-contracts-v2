import { HexString } from "ethers/lib.commonjs/utils/data";

import { type Address, type Hash } from "viem";

export interface EvmSrcChainData {
	sender: Address;
	blockNumber: string;
}

export interface DecodedArgs {
	messageId: Hash;
	messageHashSum: Hash;
	srcChainSelector: Number;
	srcChainData: EvmSrcChainData;
	operatorAddress: Address;
}

export interface MessageReportResult {
	// resultConfig
	payloadVersion: number;
	resultType: number;
	requester: Address;
	// payload
	messageId: Hash;
	messageHashSum: Hash;
	messageSender: HexString;
	srcChainSelector: Number;
	dstChainSelector: Number;
	dstChainData: string;
	allowedOperators: string[];
}
