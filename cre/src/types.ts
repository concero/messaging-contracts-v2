export type ChainSelector = string;
export type ChainId = number;
export type Log = {
    topics: string[];
    data: string;
    transactionHash: string;
};

export enum ChainType {
    EVM,
    NON_EVM,
}
export enum ResultType {
    UNKNOWN = 0,
    MESSAGE = 1,
    OPERATOR_REGISTRATION = 2,
}

