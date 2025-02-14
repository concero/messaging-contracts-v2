const COMMON_REPORT_BYTE_SIZES = {
    // Generic byte sizes & byte offsets
    ADDRESS: 20,
    WORD: 32,
    UINT32: 4,
    UINT16: 2,

    // Shared report response byte sizes
    VERSION: 1,
    REPORT_TYPE: 1,
    OPERATOR: 32,
    ARRAY_LENGTH: 4,
} as const;

const COMMON_REPORT_BYTE_OFFSETS = {
    REPORT_TYPE: 248, // 256 - 8 bits
    VERSION: 240, // 248 - 8 bits
    // 80 bits (10 bytes) reserved
    REQUESTER: 0, // 240 - 160 bits
    REQUESTER_MASK: (1n << 160n) - 1n,
};

export { COMMON_REPORT_BYTE_SIZES, COMMON_REPORT_BYTE_OFFSETS };
