import {type Hash} from "viem";

export type GlobalConfig = {
	authorizedPublicKey: string;
	deploymentsUrl: string;
};

export type DecodedArgs = {
	batches: {
        messageId: Hash;
        srcChainSelector: number;
        blockNumber: string;
    }[]
};
