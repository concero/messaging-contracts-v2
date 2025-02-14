// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library CommonConstants {
    uint8 internal constant USDC_DECIMALS = 6;
    uint16 internal constant BPS_DENOMINATOR = 10000;

    uint8 internal constant COHORTS_COUNT = 1;
    uint16 internal constant CONCERO_MESSAGE_BASE_FEE_BPS_USD = 100;
    uint256 internal constant STAKER_FEE = 1e18;

    /* Operator fees & deposits */
    uint16 internal constant OPERATOR_FEE_MESSAGE_REPORT_REQUEST_BPS_USD = 100;
    uint16 internal constant OPERATOR_FEE_MESSAGE_RELAY_BPS_USD = 100;
    uint16 internal constant OPERATOR_DEPOSIT_MESSAGE_REPORT_REQUEST_BPS_USD = 100;
    uint16 internal constant OPERATOR_DEPOSIT_REGISTRATION_REPORT_REQUEST_BPS_USD = 200;
    uint256 internal constant OPERATOR_DEPOSIT_MINIMUM_NATIVE = 1_000_000 wei; // 0.001 ETH

    /* Message */
    uint8 internal constant MESSAGE_VERSION = 1;
    uint256 internal constant MESSAGE_BASE_FEE_USD = 1e18 / 100; // 0.01 USD
    uint256 internal constant MESSAGE_MAX_SIZE = 1e6; // 1 MB
}

library MessageConfigBitOffsets {
    /* MESSAGE CONFIG BIT OFFSETS */
    uint8 internal constant OFFSET_VERSION = 248;
    uint8 internal constant OFFSET_SRC_CHAIN = 224;
    uint8 internal constant OFFSET_DST_CHAIN = 192;
    uint8 internal constant OFFSET_MIN_SRC_CONF = 176;
    uint8 internal constant OFFSET_MIN_DST_CONF = 160;
    uint8 internal constant OFFSET_RELAYER_CONF = 152;
    uint8 internal constant OFFSET_CALLBACKABLE = 151;
    uint8 internal constant OFFSET_FEE_TOKEN = 143;
}

library ReportConfigBitOffsets {
    uint8 internal constant OFFSET_REPORT_TYPE = 248; // (31 * 8)
    uint8 internal constant OFFSET_VERSION = 240; // (30 * 8)
    /// @dev 10 bytes reserved (80 bits)
    /// @dev requester occupies the last 20 bytes
}

library ReportByteSizes {
    /* GENERIC BYTE SIZES & BYTE OFFSETS */
    uint8 internal constant SIZE_ADDRESS = 20;
    uint8 internal constant SIZE_WORD = 32;
    uint8 internal constant SIZE_UINT32 = 4;
    uint8 internal constant SIZE_UINT16 = 2;

    /* SHARED REPORT RESPONSE BYTE SIZES */
    uint8 internal constant SIZE_VERSION = 1;
    uint8 internal constant SIZE_REPORT_TYPE = 1;
    uint8 internal constant SIZE_OPERATOR = 32;
    uint8 internal constant SIZE_ARRAY_LENGTH = 4;

    /* MESSAGE REPORT RESPONSE BYTE SIZES */
    uint8 internal constant SIZE_INTERNAL_MESSAGE_CONFIG = 32;
    uint8 internal constant SIZE_MESSAGE_ID = 32;
    uint8 internal constant SIZE_MESSAGE_HASH_SUM = 32;
    uint8 internal constant SIZE_DST_CHAIN_DATA_LENGTH = 4;
    uint8 internal constant SIZE_ALLOWED_OPERATORS_LENGTH = 2;
    uint8 internal constant SIZE_ALLOWED_OPERATOR = 32;
    //@dev Operator registration report doesn't have any unique fields hence no sizes are defined
}
