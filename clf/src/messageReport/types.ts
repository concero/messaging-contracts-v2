import { type Address, type Hash } from "viem";

type EvmSrcChainData = {
    sender: Address;
    blockNumber: string;
};

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
    srcChainData: string;
    operatorAddress: Address;
}

interface MessageReportResult {
    version: nu;
    mber;
    reportType: number;
    operator: Address;
    internalMessageConfig: string;
    messageId: Hash;
    messageHashSum: Hash;
    dstChainData: string;
    allowedOperators: string[];
}

export { EvmSrcChainData, DecodedArgs, InternalMessageConfig, MessageReportResult };
