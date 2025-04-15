// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

library Types {
    enum FeeToken {
        native, //                0
        usdc //                   1
    }

    struct EvmSrcChainData {
        address sender; //may not be needed
        uint256 blockNumber; // L2s have issues with blocknumber
    }

    struct EvmDstChainData {
        address receiver;
        uint256 gasLimit;
    }

    struct ClfDonReportSubmission {
        bytes32[3] context;
        bytes report;
        bytes32[] rs;
        bytes32[] ss;
        bytes rawVs;
    }

    struct ClfReport {
        bytes32[] requestIds;
        bytes[] results; // ConceroVerifier:fulfillRequest() gets results[0] as response
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
