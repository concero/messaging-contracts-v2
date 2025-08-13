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
	txHash: Hash;
	messageSender: HexString;
	srcChainSelector: Number;
	dstChainSelector: Number;
	srcBlockNumber: bigint;
	dstChainData: string;
	allowedOperators: string[];
}
