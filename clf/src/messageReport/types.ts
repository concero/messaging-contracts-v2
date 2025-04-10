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
	reportVersion: number;
	reportType: number;
	requester: Address;
	messageVersion: Number;
	messageId: Hash;
	messageHashSum: Hash;
	sender: HexString;
	srcChainSelector: Number;
	dstChainSelector: Number;
	dstChainData: string;
	shouldFinaliseSrc: Boolean;
	allowedOperators: string[];
}
