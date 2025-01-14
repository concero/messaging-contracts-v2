const INTERNAL_MESSAGE_REPORT_BIT_OFFSETS = {
    VERSION: 248n, // uint8 (8 bits, highest bits of 256-bit number)
    SRC_CHAIN_SELECTOR: 224n, // uint24 (24 bits)
    DST_CHAIN_SELECTOR: 200n, // uint24 (24 bits)
    MIN_SRC_CONF: 184n, // uint16 (16 bits)
    MIN_DST_CONF: 168n, // uint16 (16 bits)
    RELAYER_CONFIG: 160n, // uint8 (8 bits)
    IS_CALLBACKABLE: 159n,
}; // bool (1 bit)

const BIT_MASKS = {
    UINT24: 0xffffffn, // Mask for uint24 (24 bits)
    UINT16: 0xffffn, // Mask for uint16 (16 bits)
    UINT8: 0xffn, // Mask for uint8 (8 bits)
    BOOL: 0x1n, // Mask for 1 bit (bool)
};

export { BIT_MASKS, INTERNAL_MESSAGE_REPORT_BIT_OFFSETS };
