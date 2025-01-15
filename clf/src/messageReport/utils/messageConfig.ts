import { ErrorType } from "../constants/errorTypes";
import { viemChains } from "../constants/viemChains";
import { MASKS as masks, INTERNAL_MESSAGE_REPORT_BIT_OFFSETS as offsets } from "../constants/bitOffsets";
import { InternalMessageConfig } from "../types";
import { handleError } from "../../common/errorHandler";

function extractBits(config: bigint, offset: number, mask: bigint): number {
    return Number((config >> BigInt(offset)) & mask);
}

function decodeInternalMessageConfig(config: bigint): InternalMessageConfig {
    return {
        version: extractBits(config, offsets.VERSION, masks.UINT8),
        srcChainSelector: extractBits(config, offsets.SRC_CHAIN_SELECTOR, masks.UINT24),
        dstChainSelector: extractBits(config, offsets.DST_CHAIN_SELECTOR, masks.UINT24),
        minSrcConfirmations: extractBits(config, offsets.MIN_SRC_CONF, masks.UINT16),
        minDstConfirmations: extractBits(config, offsets.MIN_DST_CONF, masks.UINT16),
        relayerConfig: extractBits(config, offsets.RELAYER_CONFIG, masks.UINT8),
        isCallbackable: Boolean(extractBits(config, offsets.IS_CALLBACKABLE, masks.BOOL)),
    };
}
function validateInternalMessageConfig(config: InternalMessageConfig) {
    if (config.version === 0) handleError(ErrorType.CONFIG_INVALID_VERSION);
    if (config.relayerConfig > 255) handleError(ErrorType.CONFIG_INVALID_RELAYER_CONFIG);
    if (config.minSrcConfirmations === 0) handleError(ErrorType.CONFIG_INVALID_MIN_SRC_CONFIRMATIONS);
    if (config.minDstConfirmations === 0) handleError(ErrorType.CONFIG_INVALID_MIN_DST_CONFIRMATIONS);
    if (!viemChains[config.srcChainSelector]) handleError(ErrorType.CONFIG_INVALID_SRC_CHAIN_SELECTOR);
    if (!viemChains[config.dstChainSelector]) handleError(ErrorType.CONFIG_INVALID_DST_CHAIN_SELECTOR);
}

export { decodeInternalMessageConfig, validateInternalMessageConfig };
