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
| additional_relayers    | 8    | Bitmap of additional relayers allowed |
| minSrcConfirmations    | 16   | Min. source chain confirmations       |
| minDstConfirmations    | 16   | Min. destination chain confirmations  |
| dstChainSelector       | 24   | Destination chain ID                  |
| isCallbackable         | 1    | Callback flag (0: No, 1: Yes)         | //todo: research about finality
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
    uint8 version;
    uint24 srcChainSelector;
    uint24 dstChainSelector;
    uint16 minSrcConfirmations;
    uint16 minDstConfirmations;
    uint8 additionalRelayers;
    bool isCallbackable;
}

struct ClientMessageConfig {
    uint24 dstChainSelector;
    uint16 minSrcConfirmations;
    uint16 minDstConfirmations;
    uint8 additionalRelayers;
    FeeToken feeToken;
    bool isCallbackable;
}
// }
