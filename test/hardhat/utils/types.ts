export interface IConceroTokenAmounts {
    token: string;
    amount: bigint;
}

export interface IConceroMessageRequest {
    feeToken: string;
    dstChainSelector: bigint;
    receiver: string;
    tokenAmounts: IConceroTokenAmounts[];
    relayers: number[];
    data: string;
    extraArgs: string;
}
