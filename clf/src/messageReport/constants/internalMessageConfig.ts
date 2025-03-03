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
    VERSION: 224,
    SRC_CHAIN: 224,
    DST_CHAIN: 168,
    MIN_SRC_CONF: 152,
    MIN_DST_CONF: 136,
    RELAYER: 128,
    CALLBACKABLE: 127,
} as const;

export { INTERNAL_MESSAGE_CONFIG_SIZES, INTERNAL_MESSAGE_CONFIG_OFFSETS };
