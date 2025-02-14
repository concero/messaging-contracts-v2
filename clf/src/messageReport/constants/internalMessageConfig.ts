const INTERNAL_MESSAGE_CONFIG_SIZES = {
    VERSION: 2, // 8 bits = 2 hex chars
    SRC_CHAIN_SELECTOR: 6, // 24 bits = 6 hex chars
    RESERVED_1: 8, // 32 bits = 8 hex chars
    DST_CHAIN_SELECTOR: 6, // 24 bits = 6 hex chars
    MIN_SRC_CONF: 4, // 16 bits = 4 hex chars
    MIN_DST_CONF: 4, // 16 bits = 4 hex chars
    RELAYER_CONFIG: 2, // 8 bits = 2 hex chars
    CALLBACKABLE: 2, // 8 bits = 2 hex chars (though only 1 bit used)
} as const;

const INTERNAL_MESSAGE_CONFIG_OFFSETS = {
    VERSION: 248, // 256 - 8 bits
    SRC_CHAIN: 224, // 248 - 24 bits
    DST_CHAIN: 192, // 224 - 32 (reserved) - 24 bits
    MIN_SRC_CONF: 176, // 192 - 16 bits
    MIN_DST_CONF: 160, // 176 - 16 bits
    RELAYER: 152, // 160 - 8 bits
    CALLBACKABLE: 151, // 152 - 1 bit
} as const;

export { INTERNAL_MESSAGE_CONFIG_SIZES, INTERNAL_MESSAGE_CONFIG_OFFSETS };
