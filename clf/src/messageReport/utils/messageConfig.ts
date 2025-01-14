import { ErrorType } from "../constants/errorTypes";
import { viemChains } from "../constants/viemChains";
import { BIT_MASKS as masks, INTERNAL_MESSAGE_REPORT_BIT_OFFSETS as offsets } from "../constants/bitOffsets";
import { InternalMessageConfig } from "../types";
import { handleError } from "./errorHandler";

function decodeInternalMessageConfig(config: bigint): InternalMessageConfig {
    return {
        version: Number((config >> offsets.VERSION) & masks.UINT8),
        srcChainSelector: Number((config >> offsets.SRC_CHAIN_SELECTOR) & masks.UINT24),
        dstChainSelector: Number((config >> offsets.DST_CHAIN_SELECTOR) & masks.UINT24),
        minSrcConfirmations: Number((config >> offsets.MIN_SRC_CONF) & masks.UINT16),
        minDstConfirmations: Number((config >> offsets.MIN_DST_CONF) & masks.UINT16),
        relayerConfig: Number((config >> offsets.RELAYER_CONFIG) & masks.UINT8),
        isCallbackable: Boolean((config >> offsets.IS_CALLBACKABLE) & masks.BOOL),
    };
}

function validateInternalMessageConfig(config: InternalMessageConfig) {
    console.log(config);
    if (config.version === 0) handleError(ErrorType.CONFIG_INVALID_VERSION);
    if (config.relayerConfig > 255) handleError(ErrorType.CONFIG_INVALID_RELAYER_CONFIG);
    if (config.minSrcConfirmations === 0) handleError(ErrorType.CONFIG_INVALID_MIN_SRC_CONFIRMATIONS);
    if (config.minDstConfirmations === 0) handleError(ErrorType.CONFIG_INVALID_MIN_DST_CONFIRMATIONS);
    if (!viemChains[config.srcChainSelector]) handleError(ErrorType.CONFIG_INVALID_SRC_CHAIN_SELECTOR);
    if (!viemChains[config.dstChainSelector]) handleError(ErrorType.CONFIG_INVALID_DST_CHAIN_SELECTOR);
}

export { decodeInternalMessageConfig, validateInternalMessageConfig };
