// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;
/*
| MESSAGE CONFIG         | Bits | Description                           |
|------------------------|------|---------------------------------------|
| version                | 8    | Config version (0-255)                |
| srcChainSelector       | 24   | Source chain ID                       |
| Reserved/Unused        | 32   | Reserved for alignment (padding)      |
| dstChainSelector       | 24   | Destination chain ID                  |
| minSrcConfirmations    | 16   | Min. source chain confirmations       |
| minDstConfirmations    | 16   | Min. destination chain confirmations  |
| additional_relayers    | 8    | Bitmap of additional relayers allowed |
| isCallbackable         | 1    | Callback flag (0: No, 1: Yes)         |
| Reserved/Unused        | 174  | Reserved for future use               |
*/

// interface IMessageTypes {
enum FeeToken {
    native,
    usdc
}

struct EvmSrcChainData {
    address sender;
    uint256 blockNumber; // L2s have issues with blocknumber
}

struct EvmDstChainData {
    address receiver;
    uint256 gasLimit;
}

struct ClientMessageRequest {
    uint256 messageConfig;
    bytes dstChainData;
    bytes message;
}

struct ClientMessage {
    bytes32 messageId;
    bytes message;
}

struct InternalMessage {
    uint256 messageConfig;
    bytes32 messageId;
    bytes srcChainData;
    bytes dstChainData;
    bytes message;
}

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

struct ClientMessageConfig {
    uint24 dstChainSelector; //        ─╮
    uint16 minSrcConfirmations; //      │ Base config
    uint16 minDstConfirmations; //      │ (32 bits)
    uint8 relayerConfig; //             │
    bool isCallbackable; //            ─╯
    //
    FeeToken feeToken; //              ─  Not included in InternalMessageConfig
}
// }
