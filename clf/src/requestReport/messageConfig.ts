import { viemChains, ErrorType } from "./constants";

const OFFSET_VERSION = 248n; // uint8 (8 bits, highest bits of 256-bit number)
const OFFSET_SRC_CHAIN_SELECTOR = 224n; // uint24 (24 bits)
const OFFSET_DST_CHAIN_SELECTOR = 200n; // uint24 (24 bits)
const OFFSET_MIN_SRC_CONF = 184n; // uint16 (16 bits)
const OFFSET_MIN_DST_CONF = 168n; // uint16 (16 bits)
const OFFSET_RELAYER_CONFIG = 160n; // uint8 (8 bits)
const OFFSET_IS_CALLBACKABLE = 159n; // bool (1 bit)

const MASK_UINT24 = 0xffffffn; // Mask for uint24 (24 bits)
const MASK_UINT16 = 0xffffn; // Mask for uint16 (16 bits)
const MASK_UINT8 = 0xffn; // Mask for uint8 (8 bits)
const MASK_BOOL = 0x1n; // Mask for 1 bit (bool)

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
        version: Number((config >> OFFSET_VERSION) & MASK_UINT8),
        srcChainSelector: Number((config >> OFFSET_SRC_CHAIN_SELECTOR) & MASK_UINT24),
        dstChainSelector: Number((config >> OFFSET_DST_CHAIN_SELECTOR) & MASK_UINT24),
        minSrcConfirmations: Number((config >> OFFSET_MIN_SRC_CONF) & MASK_UINT16),
        minDstConfirmations: Number((config >> OFFSET_MIN_DST_CONF) & MASK_UINT16),
        relayerConfig: Number((config >> OFFSET_RELAYER_CONFIG) & MASK_UINT8),
        isCallbackable: Boolean((config >> OFFSET_IS_CALLBACKABLE) & MASK_BOOL),
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
