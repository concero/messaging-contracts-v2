const INTERNAL_MESSAGE_REPORT_BIT_OFFSETS = {
    VERSION: 248, // uint8 (8 bits, highest bits of 256-bit number)
    SRC_CHAIN_SELECTOR: 224, // uint24 (24 bits)
    DST_CHAIN_SELECTOR: 200, // uint24 (24 bits)
    MIN_SRC_CONF: 184, // uint16 (16 bits)
    MIN_DST_CONF: 168, // uint16 (16 bits)
    RELAYER_CONFIG: 160, // uint8 (8 bits)
    IS_CALLBACKABLE: 159, // bool (1 bit)
};

const MASKS = {
    UINT24: 0xffffffn, // Mask for uint24 (24 bits)
    UINT16: 0xffffn, // Mask for uint16 (16 bits)
    UINT8: 0xffn, // Mask for uint8 (8 bits)
    BOOL: 0x1n, // Mask for 1 bit (bool)
    UPPER_BYTE: 0xff00,
    LOWER_BYTE: 0xff,
    UPPER_BYTE_SHIFT: 8,
};

const MESSAGE_REPORT_RESULT_SIZES = {
    VERSION: 1,
    REPORT_TYPE: 1,
    OPERATOR_ADDRESS: 32,
    INTERNAL_MESSAGE_CONFIG: 32,
    MESSAGE_ID: 32,
    MESSAGE_HASH_SUM: 32,
    DST_CHAIN_DATA_LENGTH: 4,
    OPERATORS_COUNT: 2,
    OPERATOR_BYTES: 32,
};

const MESSAGE_REPORT_RESULT_OFFSETS = {
    VERSION: 0,
    REPORT_TYPE: 1, // After VERSION
    OPERATOR: 2, // After REPORT_TYPE
    MESSAGE_CONFIG: 34, // After OPERATOR
    MESSAGE_ID: 66, // After MESSAGE_CONFIG
    MESSAGE_HASH: 98, // After MESSAGE_ID
    DST_CHAIN_LENGTH: 130, // After MESSAGE_HASH
};

export { MASKS, INTERNAL_MESSAGE_REPORT_BIT_OFFSETS, MESSAGE_REPORT_RESULT_SIZES, MESSAGE_REPORT_RESULT_OFFSETS };
