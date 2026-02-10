import { Address, type Hash, Hex } from "viem";

export type GlobalConfig = {
	authorizedPublicKey: Address;
	relayerCallbackUrl: string;
	chainsConfigUrl: string;
	allowedMessageVersions: number[];
	chainsConfigHash: Hash;
};

export type DecodedArgs = {
	batch: {
		messageId: Hash;
		srcChainSelector: number;
		blockNumber: string;
	}[];
};

export type MessageSentLogData = {
	messageId: Hex;
	messageReceipt: Hex;
	validatorLibs: Address[];
	relayerLib: Address;
};

export type DecodedMessageSentReceipt = {
	version: number;
	srcChainSelector: number;
	dstChainSelector: number;
	nonce: bigint;

	srcChainData: {
		sender: Address;
		blockConfirmations: bigint;
	};

	dstChainData: {
		raw: Hex;
		receiver: Address | null;
		gasLimit: number | null;
	};

	relayerConfig: Hex;
	validatorConfigs: Hex[];
	internalValidatorConfigs: Hex[];
	payload: Hex;
};
