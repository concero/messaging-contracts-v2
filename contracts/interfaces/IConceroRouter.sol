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

    /// @notice Parameters used to retry a previously created message submission.
    /// @dev Must match **exactly** the parameters used in the original submission, regardless of the retry path:
    ///      - `retryMessageSubmission` re-attempts delivery after a client-side failure (no revalidation).
    ///      - `retryMessageSubmissionWithRevalidation` re-runs validation first (e.g., validator-side/config issues),
    ///        but the submission payload and metadata in this struct must still be identical to the original submit.
    struct RetryMessageSubmissionParams {
        /// @notice Encoded message receipt to be delivered to the destination client (must match the original submission).
        bytes messageReceipt;
        /// @notice Validator library addresses associated with the original submission.
        address[] validatorLibs;
        /// @notice Validator-produced proofs from the original submission.
        bytes[] validations;
        /// @notice Boolean validation check results from the original submission.
        bool[] validationChecks;
        /// @notice Relayer library address associated with the original submission.
        address relayerLib;
    }

    /// @notice Thrown when the caller provides less fee than required for the message.
    /// @param provided Amount of fee supplied by the caller.
    /// @param required Amount of fee required by the router.
    error InsufficientFee(uint256 provided, uint256 required);

    /// @notice Thrown when the destination chain data length is invalid.
    error InvalidDstChainDataLength();

    /// @notice Thrown when the number of validator configs does not match the number of validator libs.
    /// @param validatorConfigsCount Length of `validatorConfigs` array.
    /// @param validatorLibsCount Length of `validatorLibs` array.
    error InvalidValidatorConfigsCount(uint256 validatorConfigsCount, uint256 validatorLibsCount);

    error MessageSubmissionNotRetryable(bytes32 messageSubmossionHash);

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
    /// @param validations Validator proofs corresponding to `validatorLibs`.
    /// @param validatorLibs Validator libraries used during validation.
    /// @param validationChecks Boolean results for each validator (true if valid).
    /// @param relayerLib Relayer library that submitted the message.
    event ConceroMessageReceived(
        bytes32 indexed messageId,
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

    /// @notice Emitted when a previously submitted Concero message is retried with revalidation.
    /// @dev `newValidationChecks` contains the (possibly updated) set of validation check results used for the retry attempt.
    /// @param messageId Unique identifier of the Concero message being retried.
    /// @param newValidationChecks Boolean array representing the validation checks/results applied on retry.
    event ConceroMessageSubmissionRetriedWithRevalidation(
        bytes32 indexed messageId,
        bool[] newValidationChecks
    );

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

    /// @notice Retries delivery of a previously submitted message that failed to execute due to a client-side error.
    /// @dev Use this retry when **all validator-contract checks have already passed successfully**, but the submission
    ///      failed on the **client side** (e.g., client revert / wrong dst chain gas limit),
    ///      meaning you only need to repeat the client call.
    ///      - The retry must be performed using the **exact same parameters** and the **same validation checks/results**
    ///        that were used for the original successful validation phase.
    ///      - Can be called by anyone once a submission is marked as retryable.
    ///      - Reverts if the message has already been successfully processed.
    /// @param retryMessageSubmissionParams Params used to retry the message submission (must match the original submission).
    /// @param gasLimitOverride Gas limit override for calling the client contract.
    function retryMessageSubmission(
        RetryMessageSubmissionParams calldata retryMessageSubmissionParams,
        uint32 gasLimitOverride
    ) external;

    /// @notice Retries delivery of a previously submitted message that failed due to unsuccessful/invalid validator-side checks,
    ///         by re-running the validation phase before re-attempting the client call.
    /// @dev Use this retry when **one or more validator-contract validations did not pass**, typically due to validator
    ///      configuration issues, outdated/incorrect validator setup, or similar validator-side problems.
    ///      - Unlike `retryMessageSubmission`, this function **must re-run the validation stage** before retrying the client call.
    ///      - `internalValidatorConfigsOverrides` can be provided to fix/override validator configuration for the revalidation run.
    ///      - Can be called by anyone once a submission is marked as retryable.
    ///      - Reverts if the message has already been successfully processed.
    /// @param retryMessageSubmissionParams Params used to retry the message submission.
    /// @param internalValidatorConfigsOverrides Validator config overrides used for message submission revalidation.
    /// @param gasLimitOverride Gas limit override for calling the client contract.
    function retryMessageSubmissionWithRevalidation(
        RetryMessageSubmissionParams calldata retryMessageSubmissionParams,
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
