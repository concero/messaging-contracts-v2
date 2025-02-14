// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

/*
| INTERNAL MESSAGE CONFIG| Bits | Description                           |
|------------------------|------|---------------------------------------|
| version                | 8    | Config version (0-255)                |
| srcChainSelector       | 24   | Source chain ID                       |
| Reserved/Unused        | 32   | Reserved for alignment (padding)      |
| dstChainSelector       | 24   | Destination chain ID                  |
| minSrcConfirmations    | 16   | Min. source chain confirmations       |
| minDstConfirmations    | 16   | Min. destination chain confirmations  |
| relayer_config         | 8    | Bitmap of additional relayers allowed |
| isCallbackable         | 1    | Callback flag (0: No, 1: Yes)         |
| Reserved/Unused        | 174  | Reserved for future use               |
*/

library Types {
    enum FeeToken {
        native,
        usdc
    }

    struct EvmSrcChainData {
        address sender; //may not be needed
        uint256 blockNumber; // L2s have issues with blocknumber
    }

    struct EvmDstChainData {
        address receiver;
        uint256 gasLimit;
    }
    // @dev InternalMessageConfig is a bitmasked uint256
    struct InternalMessageConfig {
        uint8 version; //                  ─╮ Internal
        uint24 srcChainSelector; //         │ ConceroRouter config
        //	                               ─╯ 32-bit padding reserved. (36 bits total)
        uint24 dstChainSelector; //        ─╮
        uint16 minSrcConfirmations; //      │ Base config
        uint16 minDstConfirmations; //      │ (32 bits total)
        uint8 relayerConfig; //             │
        bool isCallbackable; //            ─╯
        //                                    Remaining: 174 bits
    }

    // @dev ClientMessageConfig is a bitmasked uint256
    struct ClientMessageConfig {
        uint24 dstChainSelector; //        ─╮
        uint16 minSrcConfirmations; //      │ Base config
        uint16 minDstConfirmations; //      │ (32 bits)
        uint8 relayerConfig; //             │
        bool isCallbackable; //            ─╯
        //
        FeeToken feeToken; //              ─  Not included in InternalMessageConfig
    }

    struct ClfDonReportSubmission {
        bytes32[3] context;
        bytes report;
        bytes32[] rs;
        bytes32[] ss;
        bytes rawVs;
    }
}
