import { WriteContractParameters } from "viem";
import type { WaitForTransactionReceiptParameters } from "viem/actions/public/waitForTransactionReceipt";

import { ConceroNetwork } from "../types/ConceroNetwork";

enum ProxyEnum {
	routerProxy = "routerProxy",
	verifierProxy = "verifierProxy",
	priceFeedProxy = "priceFeedProxy",
	creValidatorLibProxy = "creValidatorLibProxy",
	relayerLibProxy = "relayerLibProxy",
}

const viemReceiptConfig: WaitForTransactionReceiptParameters = {
	timeout: 0,
	confirmations: 2,
};

const writeContractConfig: WriteContractParameters = {
	gas: 3000000n, // 3M
};

function getViemReceiptConfig(chain: ConceroNetwork): Partial<WaitForTransactionReceiptParameters> {
	return {
		timeout: 0,
		confirmations: chain.confirmations,
	};
}

const ADMIN_ROLE = "0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42";

export { viemReceiptConfig, writeContractConfig, ProxyEnum, getViemReceiptConfig, ADMIN_ROLE };
