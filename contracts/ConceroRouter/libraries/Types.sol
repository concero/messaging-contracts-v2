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
        bytes report; // ClfReport
        bytes32[] rs;
        bytes32[] ss;
        bytes rawVs;
    }

    struct ClfReport {
        bytes32[] requestIds;
        bytes[] results;
        bytes[] errors;
        bytes[] onchainMetadata;
        bytes[] offchainMetadata;
    }

    struct ClfReportOnchainMetadata {
      bytes32 requestId; // ═════════════════╸ A unique identifier for a Chainlink Functions request
      address coordinator; // ═══════════════╗ The Coordinator contract that manages the DON that is servicing a request
      uint96 estimatedTotalCostJuels; // ════╝ The maximum cost in Juels (1e18) of LINK that will be charged to fulfill a request
      address client; // ════════════════════╗ The client contract that sent the request
      uint64 subscriptionId; //              ║ Identifier of the billing subscription that will be charged for the request
      uint32 callbackGasLimit; // ═══════════╝ The amount of gas that the callback to the consuming contract will be given
      uint72 adminFee; // ═══════════════════╗ Flat fee (in Juels of LINK) that will be paid to the Router Owner for operation of the network
      uint72 donFee; //                      ║ Fee (in Juels of LINK) that will be split between Node Operators for servicing a request
      uint40 gasOverheadBeforeCallback; //   ║ Represents the average gas execution cost before the fulfillment callback.
      uint40 gasOverheadAfterCallback; //    ║ Represents the average gas execution cost after the fulfillment callback.
      uint32 timeoutTimestamp; // ═══════════╝ The timestamp at which a request will be eligible to be timed out
    }
}
