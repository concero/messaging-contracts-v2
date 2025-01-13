import { viemChains, ErrorType, INTERNAL_MESSAGE_REPORT_BIT_OFFSETS as offsets, BIT_MASKS as masks } from "./constants";

interface InternalMessageConfig {
    version: number; // uint8
    srcChainSelector: number; // uint24
    dstChainSelector: number; // uint24
    minSrcConfirmations: number; // uint16
    minDstConfirmations: number; // uint16
    relayerConfig: number; // uint8
    isCallbackable: boolean; // bool
}

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
    if (config.version === 0) throw new Error(ErrorType.CONFIG_INVALID_VERSION);
    if (config.relayerConfig > 255) throw new Error(ErrorType.CONFIG_INVALID_RELAYER_CONFIG);
    if (config.minSrcConfirmations === 0) throw new Error(ErrorType.CONFIG_INVALID_MIN_SRC_CONFIRMATIONS);
    if (config.minDstConfirmations === 0) throw new Error(ErrorType.CONFIG_INVALID_MIN_DST_CONFIRMATIONS);
    if (!viemChains[config.srcChainSelector]) throw new Error(ErrorType.CONFIG_INVALID_SRC_CHAIN_SELECTOR);
    if (!viemChains[config.dstChainSelector]) throw new Error(ErrorType.CONFIG_INVALID_DST_CHAIN_SELECTOR);
}

export { decodeInternalMessageConfig, validateInternalMessageConfig };
