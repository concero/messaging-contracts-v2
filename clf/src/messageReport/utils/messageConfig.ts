import { MASKS } from "../../common/bitMasks";
import { handleError } from "../../common/errorHandler";
import { ErrorType } from "../../common/errorType";
import { viemChains } from "../../common/viemChains";
import { INTERNAL_MESSAGE_CONFIG_OFFSETS as OFFSETS } from "../constants/internalMessageConfig";
import { InternalMessageConfig } from "../types";

export function decodeInternalMessageConfig(config: string): InternalMessageConfig {
	const bigIntConfig = BigInt(config);

	return {
		version: (bigIntConfig >> BigInt(OFFSETS.VERSION)) & MASKS.UINT8,
		srcChainSelector: (bigIntConfig >> BigInt(OFFSETS.SRC_CHAIN)) & MASKS.UINT24,
		dstChainSelector: (bigIntConfig >> BigInt(OFFSETS.DST_CHAIN)) & MASKS.UINT24,
		minSrcConfirmations: (bigIntConfig >> BigInt(OFFSETS.MIN_SRC_CONF)) & MASKS.UINT16,
		minDstConfirmations: (bigIntConfig >> BigInt(OFFSETS.MIN_DST_CONF)) & MASKS.UINT16,
		relayerConfig: (bigIntConfig >> BigInt(OFFSETS.RELAYER)) & MASKS.UINT8,
		isCallbackable: Boolean((bigIntConfig >> BigInt(OFFSETS.CALLBACKABLE)) & MASKS.BOOL),
	};
}

export function validateInternalMessageConfig(config: InternalMessageConfig) {
	if (config.version === 0n) handleError(ErrorType.CONFIG_INVALID_VERSION);
	if (config.relayerConfig > 255n) handleError(ErrorType.CONFIG_INVALID_RELAYER_CONFIG);
	if (config.minSrcConfirmations === 0n) handleError(ErrorType.CONFIG_INVALID_MIN_SRC_CONFIRMATIONS);
	if (config.minDstConfirmations === 0n) handleError(ErrorType.CONFIG_INVALID_MIN_DST_CONFIRMATIONS);
	if (!viemChains[config.srcChainSelector.toString()]) handleError(ErrorType.CONFIG_INVALID_SRC_CHAIN_SELECTOR);
	if (!viemChains[config.dstChainSelector.toString()]) handleError(ErrorType.CONFIG_INVALID_DST_CHAIN_SELECTOR);
	if (config.srcChainSelector === config.dstChainSelector) handleError(ErrorType.CONFIG_SAME_CHAINS);
}
