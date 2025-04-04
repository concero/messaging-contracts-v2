import { HexString } from "ethers/lib.commonjs/utils/data";

import { type Address, type Hash } from "viem";

interface EvmSrcChainData {
	sender: Address;
	blockNumber: string;
}

interface InternalMessageConfig {
	version: bigint; // uint8
	srcChainSelector: bigint; // uint24
	dstChainSelector: bigint; // uint24
	minSrcConfirmations: bigint; // uint16
	minDstConfirmations: bigint; // uint16
	relayerConfig: bigint; // uint8
	isCallbackable: boolean; // bool
}

interface DecodedArgs {
	internalMessageConfig: InternalMessageConfig;
	messageId: Hash;
	messageHashSum: Hash;
	srcChainData: EvmSrcChainData;
	operatorAddress: Address;
}

interface MessageReportResult {
	reportType: number; //                ─╮
	version: number; //                    │ Report Response Config
	// 10 bytes reserved for future use    │ Packed as a uint256
	requester: Address; //                ─╯
	internalMessageConfig: string;
	messageId: Hash;
	messageHashSum: Hash;
	sender: HexString;
	dstChainData: string;
	allowedOperators: string[];
}

export { EvmSrcChainData, DecodedArgs, InternalMessageConfig, MessageReportResult };
