import { DomainError, ErrorCode } from "../helpers";
import { ChainsManager } from "../systems";
import { MessagingCodec } from "./codec";
import { fetchLogByMessageId } from "./fetchLogByMessageId";

export const validateRelayerLib = (log: Awaited<ReturnType<typeof fetchLogByMessageId>>): void => {
	const parsedReceipt = MessagingCodec.decodeReceipt(log.data.messageReceipt);
	const srcChain = ChainsManager.getOptionsBySelector(parsedReceipt.srcChainSelector);

	if (parsedReceipt.relayerLib !== srcChain.deployments.relayerLib) {
		throw new DomainError(ErrorCode.UNKNOWN_ERROR, "RelayerLib was not found");
	}
};
