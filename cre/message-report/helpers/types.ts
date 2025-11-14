import { type Hash } from "viem";

export type GlobalConfig = {
	authorizedPublicKey: string;
	deploymentsUrl: string;
};

export type DecodedArgs = {
	messageId: Hash;
	srcChainSelector: number;
	blockNumber: string;
};
