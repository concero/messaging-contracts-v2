// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity ^0.8.20;

interface IConceroRouter {
    /// @notice Message description used when sending a cross-chain Concero message.
    /// @dev
    /// - `dstChainSelector`: target chain identifier for the message.
    /// - `srcBlockConfirmations`: number of source chain confirmations required before processing.
    /// - `feeToken`: address of the token used to pay fees (address(0) for native token).
    /// - `relayerLib`: relayer library responsible for pricing and validating relayers.
    /// - `validatorLibs`: set of validator libraries that must validate the message.
    /// - `validatorConfigs`: per-validator configuration blobs to be embedded in the message.
    /// - `relayerConfig`: configuration blob for the relayer on the destination chain.
    /// - `dstChainData`: encoded destination chain data (e.g. receiver address, gas limit).
    /// - `payload`: arbitrary payload passed to the destination client.
    struct MessageRequest {
        uint24 dstChainSelector;
        uint64 srcBlockConfirmations;
        address feeToken;
        address relayerLib;
        address[] validatorLibs;
        bytes[] validatorConfigs;
        bytes relayerConfig;
        bytes dstChainData;
        bytes payload;
    }

    /// @notice Breakdown of the fee paid for a message.
    /// @dev
    /// - `relayer`: amount paid to the relayer lib / relayer.
    /// - `validatorsFee`: individual fees paid to validators.
    /// - `token`: address of the fee token (address(0) for native).
    struct Fee {
        uint256 relayer;
        uint256[] validatorsFee;
        address token;
    }

    /// @notice Thrown when the caller provides less fee than required for the message.
    /// @param provided Amount of fee supplied by the caller.
    /// @param required Amount of fee required by the router.
    error InsufficientFee(uint256 provided, uint256 required);

    /// @notice Thrown when the destination chain data is empty.
    error EmptyDstChainData();

    /// @notice Thrown when the number of validator configs does not match the number of validator libs.
    /// @param validatorConfigsCount Length of `validatorConfigs` array.
    /// @param validatorLibsCount Length of `validatorLibs` array.
    error InvalidValidatorConfigsCount(uint256 validatorConfigsCount, uint256 validatorLibsCount);

    /// @notice Emitted when a Concero message is constructed and ready to be relayed cross-chain.
    /// @param messageId Unique identifier (hash) of the message receipt.
    /// @param messageReceipt Packed message receipt bytes containing all routing metadata.
    /// @param validatorLibs Addresses of validator libraries required to validate the message.
    /// @param relayerLib Address of the relayer library responsible for this message.
    event ConceroMessageSent(
        bytes32 indexed messageId,
        bytes messageReceipt,
        address[] validatorLibs,
        address relayerLib
    );

    /// @notice Emitted when the fee for a Concero message is successfully collected.
    /// @param messageId Unique identifier (hash) of the message.
    /// @param fee Breakdown of the total fee paid (relayer + validators + token).
    event ConceroMessageFeePaid(bytes32 indexed messageId, Fee fee);

    /// @notice Emitted when a Concero message is received on the destination chain.
    /// @dev
    /// - Includes raw validations, validator libs and their evaluation results.
    /// @param messageId Unique identifier (hash) of the message.
    /// @param messageReceipt Packed message receipt bytes.
    /// @param validations Validator proofs corresponding to `validatorLibs`.
    /// @param validatorLibs Validator libraries used during validation.
    /// @param validationChecks Boolean results for each validator (true if valid).
    /// @param relayerLib Relayer library that submitted the message.
    event ConceroMessageReceived(
        bytes32 indexed messageId,
        bytes messageReceipt,
        bytes[] validations,
        address[] validatorLibs,
        bool[] validationChecks,
        address relayerLib
    );

    /// @notice Emitted when a Concero message is successfully delivered to the destination client.
    /// @param messageId Unique identifier (hash) of the delivered message.
    event ConceroMessageDelivered(bytes32 indexed messageId);

    /// @notice Emitted when a Concero message delivery to the destination client fails.
    /// @param messageId Unique identifier (hash) of the message that failed.
    /// @param error Return data from the failed call (may contain revert reason).
    event ConceroMessageDeliveryFailed(bytes32 indexed messageId, bytes error);

    /**
     * @notice Concero allows you to send messages from one blockchain
     *         to another using the `conceroSend` function. This enables
     *         cross-chain interactions for a variety of use cases:
     *         token transfers, governance actions, or any custom
     *         cross-chain operations.
     * **/
    function conceroSend(
        MessageRequest calldata messageRequest
    ) external payable returns (bytes32 messageId);

    /// @notice Retries delivery of a previously submitted message that failed to execute.
    /// @dev
    /// - Can be called by anyone once a submission is marked as retryable.
    /// - Checks that the message has not been successfully processed yet.
    /// - Clears the `isMessageRetryable` flag before re-attempting delivery.
    /// @param messageReceipt Packed encoded message receipt.
    /// @param validationChecks Cached validation results from the previous submission.
    /// @param validatorLibs Validator libs that were used when the message was first submitted.
    /// @param relayerLib Relayer lib used for the original submission.
    /// @param gasLimitOverride gas limit override for calling a client contract
    function retryMessageSubmission(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib,
        uint32 gasLimitOverride
    ) external;

    /// @notice Retries delivery of a previously submitted message that failed to execute with re-validation process.
    /// @dev
    /// - Can be called by anyone once a submission is marked as retryable.
    /// - Checks that the message has not been successfully processed yet.
    /// - Clears the `isMessageRetryable` flag before re-attempting delivery.
    /// - Performs re-validation of the message using the provided relayer lib and validator libs.
    /// @param messageReceipt Packed encoded message receipt.
    /// @param validations Validator proofs corresponding to `validatorLibs`.
    /// @param validationChecks Result of first validation checks. Is needed to get the message submission hash.
    /// @param validatorLibs Validator libs that were used when the message was first submitted.
    /// @param relayerLib Relayer lib used for the original submission.
    /// @param internalValidatorConfigsOverrides config used for messageSubmission revalidation
    /// @param gasLimitOverride gas limit override for calling a client contract
    function retryMessageSubmissionWithRevalidation(
        bytes calldata messageReceipt,
        bytes[] calldata validations,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib,
        bytes[] calldata internalValidatorConfigsOverrides,
        uint32 gasLimitOverride
    ) external;

    /**
     * @notice Before sending a message, you must call getMessageFee.
     *         If you choose to pay fees in the native token, pass the
     *         returned value as msg.value.
     */
    function getMessageFee(MessageRequest calldata messageRequest) external view returns (uint256);
}
