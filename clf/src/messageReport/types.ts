import { Address } from "viem";

type EvmSrcChainData = {
    sender: Address;
    blockNumber: string;
};

interface MessageArgs {
    internalMessageConfig: string;
    messageId: string;
    messageHashSum: string;
    srcChainData: string;
    operatorAddress: string;
}

interface InternalMessageConfig {
    version: number; // uint8
    srcChainSelector: number; // uint24
    dstChainSelector: number; // uint24
    minSrcConfirmations: number; // uint16
    minDstConfirmations: number; // uint16
    relayerConfig: number; // uint8
    isCallbackable: boolean; // bool
}

interface MessageReportResult {
    version: number;
    reportType: number;
    operator: string;
    internalMessageConfig: string;
    messageId: string;
    messageHashSum: string;
    dstChainData: string;
    allowedOperators: string[];
}

export { EvmSrcChainData, MessageArgs, InternalMessageConfig, MessageReportResult };
