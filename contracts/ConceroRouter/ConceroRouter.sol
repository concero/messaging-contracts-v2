// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "../common/CommonErrors.sol";
import {IConceroClient} from "../interfaces/IConceroClient.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IRelayerLib} from "../interfaces/IRelayerLib.sol";
import {IRelayer} from "../interfaces/IRelayer.sol";
import {IValidatorLib} from "../interfaces/IValidatorLib.sol";
import {MessageCodec} from "../common/libraries/MessageCodec.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Storage as s} from "./libraries/Storage.sol";
import {ValidatorCodec} from "../common/libraries/ValidatorCodec.sol";
import {Utils} from "../common/libraries/Utils.sol";

/// @title ConceroRouter
/// @notice Core router contract that coordinates Concero cross-chain messaging.
/// @dev
/// - Accepts message requests from Concero clients and emits them for relayers.
/// - Collects and distributes fees to relayers and validators.
/// - Validates and delivers messages on the destination chain via registered validator libs.
/// - Implements retry logic for failed deliveries.
contract ConceroRouter is IConceroRouter, IRelayer, ReentrancyGuardUpgradeable {
    using s for s.Router;
    using SafeERC20 for IERC20;
    using MessageCodec for MessageRequest;
    using MessageCodec for bytes;
    using ValidatorCodec for bytes;

    /// @notice Parameters required to deliver a message to the destination client contract.
    /// @dev This struct bundles everything needed to perform the `conceroReceive` call and to track delivery state.
    ///      - `messageHash` is the unique identifier used to mark a message as processed and to emit delivery events.
    ///      - `messageSubmissionHash` identifies the original submission record that can be marked as retryable on failure.
    ///      - `isRetry` indicates whether this delivery attempt is executed as part of a retry flow:
    ///        * when `false`, a failed delivery may mark the original submission as retryable;
    ///        * when `true`, failures must **not** create/mark new retryable submissions (only the original submission is retryable).
    struct DeliverMessageParams {
        /// @notice Encoded message receipt passed to the client’s `conceroReceive`.
        bytes messageReceipt;
        /// @notice Addresses of validator libraries used for this delivery attempt.
        address[] validatorLibs;
        /// @notice Validation checks applied for this delivery attempt (must correspond to the validation phase).
        bool[] validationChecks;
        /// @notice Unique hash of the message used for processed-tracking and delivery events.
        bytes32 messageHash;
        /// @notice Hash identifying the original submission record for retryability tracking.
        bytes32 messageSubmissionHash;
        /// @notice Address of the relayer library associated with this delivery attempt.
        address relayerLib;
        /// @notice Destination client contract that will receive the message (`conceroReceive` target).
        address receiver;
        /// @notice Gas limit used for the low-level call to the client contract.
        uint32 gasLimit;
        /// @notice Whether this delivery attempt is a retry (true) or the initial attempt (false).
        bool isRetry;
    }
    uint8 internal constant NATIVE_DECIMALS = 18;

    uint24 internal immutable i_chainSelector;
    uint256 internal immutable i_chainID;

    constructor(uint24 chainSelector) {
        i_chainSelector = chainSelector;
        i_chainID = block.chainid;
    }

    // INITIALIZER //

    function initialize() external initializer {
        __ReentrancyGuard_init();
    }

    receive() external payable {}

    /// @inheritdoc IConceroRouter
    /// @dev
    /// - Validates the message request (destination data, validator config lengths).
    /// - Collects fees for relayer and validators.
    /// - Builds a packed message receipt and emits `ConceroMessageSent` and `ConceroMessageFeePaid`.
    /// - Returns a deterministic `messageId` (hash of the message receipt).
    function conceroSend(
        MessageRequest calldata messageRequest
    ) external payable returns (bytes32) {
        _whenChainNotForked();
        _validateMessageParams(messageRequest);
        (Fee memory fee, bytes[] memory validatorConfigs) = _collectMessageFee(messageRequest);

        bytes memory packedMessageReceipt = messageRequest.toMessageReceiptBytes(
            i_chainSelector,
            msg.sender,
            ++s.router().nonce[msg.sender][i_chainSelector][messageRequest.dstChainSelector],
            validatorConfigs
        );

        bytes32 messageId = keccak256(packedMessageReceipt);

        emit ConceroMessageSent(
            messageId,
            packedMessageReceipt,
            messageRequest.validatorLibs,
            messageRequest.relayerLib
        );
        emit ConceroMessageFeePaid(messageId, fee);

        return messageId;
    }

    /// @inheritdoc IRelayer
    function submitMessage(
        bytes calldata messageReceipt,
        bytes[] calldata validations,
        address[] calldata validatorLibs,
        address relayerLib
    ) external nonReentrant {
        _whenChainNotForked();

        require(
            messageReceipt.dstChainSelector() == i_chainSelector,
            InvalidDstChainSelector(messageReceipt.dstChainSelector(), i_chainSelector)
        );
        require(
            validatorLibs.length == validations.length,
            InvalidValidationsCount(validatorLibs.length, validations.length)
        );

        _validateValidatorLibs(validatorLibs);

        bytes32 messageHash = keccak256(messageReceipt);
        require(!s.router().isMessageProcessed[messageHash], MessageAlreadyProcessed(messageHash));

        IRelayerLib(relayerLib).validate(messageReceipt, msg.sender);

        bool[] memory validationChecks = _performValidationChecks(
            messageReceipt,
            validations,
            validatorLibs,
            messageReceipt.internalValidatorsConfig()
        );

        bytes32 messageSubmissionHash = getMessageSubmissionHash(
            messageReceipt,
            relayerLib,
            validatorLibs,
            validationChecks,
            validations
        );

        require(
            !s.router().isMessageRetryable[messageSubmissionHash],
            MessageSubmissionAlreadyProcessed(messageSubmissionHash)
        );

        emit ConceroMessageReceived(
            messageHash,
            validations,
            validatorLibs,
            validationChecks,
            relayerLib
        );

        (address receiver, uint32 gasLimit) = messageReceipt.evmDstChainData();

        _deliverMessage(
            DeliverMessageParams({
                messageReceipt: messageReceipt,
                validatorLibs: validatorLibs,
                validationChecks: validationChecks,
                messageHash: messageHash,
                messageSubmissionHash: messageSubmissionHash,
                relayerLib: relayerLib,
                receiver: receiver,
                gasLimit: gasLimit,
                isRetry: false
            })
        );
    }

    /// @inheritdoc IConceroRouter
    function retryMessageSubmission(
        RetryMessageSubmissionParams calldata retryMessageSubmissionParams,
        uint32 gasLimitOverride
    ) external nonReentrant {
        _whenChainNotForked();

        bytes32 messageHash = _validateRetryableMessageSubmission(retryMessageSubmissionParams);

        (address receiver, ) = retryMessageSubmissionParams.messageReceipt.evmDstChainData();

        _deliverMessage(
            DeliverMessageParams({
                messageReceipt: retryMessageSubmissionParams.messageReceipt,
                validatorLibs: retryMessageSubmissionParams.validatorLibs,
                validationChecks: retryMessageSubmissionParams.validationChecks,
                messageHash: messageHash,
                messageSubmissionHash: getMessageSubmissionHash(
                    retryMessageSubmissionParams.messageReceipt,
                    retryMessageSubmissionParams.relayerLib,
                    retryMessageSubmissionParams.validatorLibs,
                    retryMessageSubmissionParams.validationChecks,
                    retryMessageSubmissionParams.validations
                ),
                relayerLib: retryMessageSubmissionParams.relayerLib,
                receiver: receiver,
                gasLimit: gasLimitOverride,
                isRetry: true
            })
        );
    }

    /// @inheritdoc IConceroRouter
    function retryMessageSubmissionWithRevalidation(
        RetryMessageSubmissionParams calldata retryMessageSubmissionParams,
        bytes[] calldata internalValidatorConfigsOverrides,
        uint32 gasLimitOverride
    ) external nonReentrant {
        _whenChainNotForked();

        bytes32 messageHash = _validateRetryableMessageSubmission(retryMessageSubmissionParams);

        bool[] memory newValidationChecks = _performValidationChecks(
            retryMessageSubmissionParams.messageReceipt,
            retryMessageSubmissionParams.validations,
            retryMessageSubmissionParams.validatorLibs,
            internalValidatorConfigsOverrides
        );

        emit ConceroMessageSubmissionRetriedWithRevalidation(messageHash, newValidationChecks);

        (address receiver, ) = retryMessageSubmissionParams.messageReceipt.evmDstChainData();

        _deliverMessage(
            _retryMessageParamsToDeliverMessageParams(
                retryMessageSubmissionParams,
                messageHash,
                newValidationChecks,
                receiver,
                gasLimitOverride
            )
        );
    }

    /// @notice Withdraws accumulated relayer fees for the caller across multiple fee tokens.
    /// @dev
    /// - For each token in `tokens`, sends the earned fee balance to `msg.sender`.
    /// - Supports both native token (`address(0)`) and ERC-20 fee tokens.
    /// - Emits `RelayerFeeWithdrawn` for each non-zero withdrawal.
    /// @param tokens List of fee token addresses to withdraw (use address(0) for native).
    function withdrawRelayerFee(address[] calldata tokens) external nonReentrant {
        s.Router storage s_router = s.router();

        for (uint256 i; i < tokens.length; ++i) {
            uint256 relayerFee = s_router.relayerFeeEarned[msg.sender][tokens[i]];
            s_router.relayerFeeEarned[msg.sender][tokens[i]] = 0;

            if (relayerFee == 0) continue;

            if (tokens[i] == address(0)) {
                Address.sendValue(payable(msg.sender), relayerFee);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, relayerFee);
            }

            emit RelayerFeeWithdrawn(msg.sender, tokens[i], relayerFee);
        }
    }

    /* VIEW FUNCTIONS */

    /* @inheritdoc IConceroRouter */
    function getMessageFee(MessageRequest calldata messageRequest) external view returns (uint256) {
        _validateMessageParams(messageRequest);

        (, bytes[] memory validatorConfigs, uint256 validatorsFee) = _getValidatorsFeeAndConfigs(
            messageRequest
        );

        return
            IRelayerLib(messageRequest.relayerLib).getFee(messageRequest, validatorConfigs) +
            validatorsFee;
    }

    /// @notice Returns the total relayer fee accrued for a given relayer library and token.
    /// @param relayerLib Address of the relayer library.
    /// @param feeToken Address of the fee token (use address(0) for native).
    /// @return Amount of fees earned and currently stored in the router.
    function getRelayerFeeEarned(
        address relayerLib,
        address feeToken
    ) public view returns (uint256) {
        return s.router().relayerFeeEarned[relayerLib][feeToken];
    }

    // @notice Checks if a message has already been successfully processed.
    /// @param messageId Hash of the message receipt (message ID).
    /// @return True if the message delivery succeeded, otherwise false.
    function isMessageProcessed(bytes32 messageId) public view returns (bool) {
        return s.router().isMessageProcessed[messageId];
    }

    /// @notice Checks if a message submission is currently marked as retryable.
    /// @param messageId Hash of the message receipt.
    /// @param messageSubmissionHash Hash of the message submission.
    /// @return True if the message can be retried, otherwise false.
    function isMessageSubmissionRetryable(
        bytes32 messageId,
        bytes32 messageSubmissionHash
    ) public view returns (bool) {
        s.Router storage s_router = s.router();

        return
            !s_router.isMessageProcessed[messageId] &&
            s_router.isMessageRetryable[messageSubmissionHash];
    }

    function getMessageSubmissionHash(
        bytes memory messageReceipt,
        address relayerLib,
        address[] memory validatorLibs,
        bool[] memory validationChecks,
        bytes[] memory validations
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(messageReceipt, relayerLib, validatorLibs, validationChecks, validations)
            );
    }

    /* INTERNAL FUNCTIONS */

    /// @notice Delivers a message to the receiver on the destination chain by calling the client’s `conceroReceive`.
    /// @dev Performs a low-level call to `IConceroClient(receiver).conceroReceive(...)` with an explicit gas limit.
    ///
    ///      **Success path**
    ///      - Marks the message as processed (`isMessageProcessed[messageHash] = true`).
    ///      - Emits `ConceroMessageDelivered(messageHash)`.
    ///
    ///      **Failure path**
    ///      - Treats the failure as a **client-side execution failure** (the call reverted / returned failure).
    ///      - If this is the **initial (non-retry) delivery attempt** (`isRetry == false`):
    ///        * marks the original submission as retryable (`isMessageRetryable[messageSubmissionHash] = true`),
    ///          so the client call can be repeated later using the original submission.
    ///      - If this is called from a **retry flow** (`isRetry == true`):
    ///        * does **not** create/mark any new retryable submission (only the originally created submission may be retried).
    ///      - Emits `ConceroMessageDeliveryFailed(messageHash, returnedData)` with the raw returned/revert data.
    /// @param deliverMessageParams Parameters used to perform the delivery call to the client contract.
    function _deliverMessage(DeliverMessageParams memory deliverMessageParams) internal {
        bytes memory callData = abi.encodeWithSelector(
            IConceroClient.conceroReceive.selector,
            deliverMessageParams.messageReceipt,
            deliverMessageParams.validationChecks,
            deliverMessageParams.validatorLibs,
            deliverMessageParams.relayerLib
        );

        (bool success, bytes memory res) = Utils.safeCall(
            deliverMessageParams.receiver,
            deliverMessageParams.gasLimit,
            0,
            256,
            callData
        );

        if (success) {
            s.router().isMessageProcessed[deliverMessageParams.messageHash] = true;
            emit ConceroMessageDelivered(deliverMessageParams.messageHash);
        } else {
            /* @dev If _deliverMessage was called from retry functions,
             *      we do not create a new submission and do not
             *      allow it to be retried. Only the submission that was
             *      originally created can be retried. */
            if (!deliverMessageParams.isRetry) {
                s.router().isMessageRetryable[deliverMessageParams.messageSubmissionHash] = true;
            }

            emit ConceroMessageDeliveryFailed(deliverMessageParams.messageHash, res);
        }
    }

    /// @notice Executes validator checks for a given message on this destination chain.
    /// @dev
    /// - For each validator:
    ///   * reads its internal gas config from the message,
    ///   * staticcalls `IValidatorLib.isValid` with the given validation proof,
    ///   * expects a single 32-byte word that decodes to 1 on success.
    /// - Checks for duplicate validator libraries.
    /// - If a validation proof is empty or the call fails, the corresponding check is false.
    /// @param messageReceipt Encoded message receipt.
    /// @param validations Validator proofs (one per validator).
    /// @param validatorLibs Validator libraries deployed on this chain.
    /// @param internalValidatorConfigs Config containing the information necessary to perform correct validation on the dst chain in validatorLibs
    /// @return validationChecks Boolean array indicating which validators approved the message.
    function _performValidationChecks(
        bytes calldata messageReceipt,
        bytes[] calldata validations,
        address[] memory validatorLibs,
        bytes[] memory internalValidatorConfigs
    ) internal view returns (bool[] memory) {
        bool[] memory validationChecks = new bool[](validatorLibs.length);

        for (uint256 i; i < validationChecks.length; ++i) {
            if (validations[i].length == 0) {
                validationChecks[i] = false;
            } else {
                uint32 validationGasLimit = internalValidatorConfigs[i].evmConfig();

                bytes memory callData = abi.encodeWithSelector(
                    IValidatorLib.isValid.selector,
                    messageReceipt,
                    validations[i]
                );

                (bool success, bytes memory result) = validatorLibs[i].staticcall{
                    gas: validationGasLimit
                }(callData);

                if (success && result.length == 32) {
                    validationChecks[i] = abi.decode(result, (uint256)) == 1;
                } else {
                    validationChecks[i] = false;
                }
            }
        }

        return validationChecks;
    }

    function _validateMessageParams(MessageRequest calldata messageRequest) internal pure {
        require(messageRequest.dstChainData.length > 0, EmptyDstChainData());
        require(
            messageRequest.validatorConfigs.length == messageRequest.validatorLibs.length,
            InvalidValidatorConfigsCount(
                messageRequest.validatorConfigs.length,
                messageRequest.validatorLibs.length
            )
        );
    }

    function _validateRetryableMessageSubmission(
        RetryMessageSubmissionParams memory retryMessageSubmissionParams
    ) internal view returns (bytes32) {
        s.Router storage s_router = s.router();

        bytes32 messageHash = keccak256(retryMessageSubmissionParams.messageReceipt);
        require(!s_router.isMessageProcessed[messageHash], MessageAlreadyProcessed(messageHash));

        bytes32 messageSubmissionHash = getMessageSubmissionHash(
            retryMessageSubmissionParams.messageReceipt,
            retryMessageSubmissionParams.relayerLib,
            retryMessageSubmissionParams.validatorLibs,
            retryMessageSubmissionParams.validationChecks,
            retryMessageSubmissionParams.validations
        );
        require(
            s_router.isMessageRetryable[messageSubmissionHash],
            MessageSubmissionNotRetryable(messageSubmissionHash)
        );

        return messageHash;
    }

    /// @notice Collects message fees from the caller and accounts them to the relayer.
    /// @dev
    /// - Queries validator fees and configs via `_getValidatorsFeeAndConfigs`.
    /// - Queries relayer fee via `IRelayerLib.getFee`.
    /// - Ensures correct `msg.value` (for native fee) or pulls ERC-20 tokens from sender.
    /// - Accumulates the total fee into `relayerFeeEarned[relayerLib][feeToken]`.
    /// @param messageRequest Message request being sent.
    /// @return fee Fee breakdown (per-validator + relayer + fee token).
    /// @return operatorConfigs Validator operator configs obtained from validator libs.
    function _collectMessageFee(
        MessageRequest calldata messageRequest
    ) internal returns (Fee memory, bytes[] memory) {
        s.Router storage s_router = s.router();

        (
            uint256[] memory validatorsFee,
            bytes[] memory operatorConfigs,
            uint256 totalValidatorsFee
        ) = _getValidatorsFeeAndConfigs(messageRequest);

        uint256 relayerFee = IRelayerLib(messageRequest.relayerLib).getFee(
            messageRequest,
            operatorConfigs
        );

        uint256 totalRelayerFee = relayerFee + totalValidatorsFee;

        if (messageRequest.feeToken == address(0)) {
            require(msg.value == totalRelayerFee, InsufficientFee(msg.value, totalRelayerFee));
        } else {
            IERC20(messageRequest.feeToken).safeTransferFrom(
                msg.sender,
                address(this),
                totalRelayerFee
            );
        }

        s_router.relayerFeeEarned[messageRequest.relayerLib][
            messageRequest.feeToken
        ] += totalRelayerFee;

        return (
            Fee({
                relayer: relayerFee,
                validatorsFee: validatorsFee,
                token: messageRequest.feeToken
            }),
            operatorConfigs
        );
    }

    /// @notice Computes validator fees and configs for a given message request.
    /// @dev
    /// - Iterates over `validatorLibs` and calls `getFeeAndValidatorConfig` on each.
    /// - Aggregates the per-validator fees into `totalValidatorsFee`.
    /// @param messageRequest Message request being priced.
    /// @return validatorsFee Array of fees per validator.
    /// @return validatorConfigs Array of validator configs to embed in the message.
    /// @return totalValidatorsFee Sum of all validator fees.
    function _getValidatorsFeeAndConfigs(
        MessageRequest calldata messageRequest
    ) internal view returns (uint256[] memory, bytes[] memory, uint256) {
        uint256[] memory validatorsFee = new uint256[](messageRequest.validatorLibs.length);
        bytes[] memory validatorConfigs = new bytes[](messageRequest.validatorLibs.length);
        uint256 totalValidatorsFee;

        for (uint256 i; i < messageRequest.validatorLibs.length; ++i) {
            (validatorsFee[i], validatorConfigs[i]) = IValidatorLib(messageRequest.validatorLibs[i])
                .getFeeAndValidatorConfig(messageRequest);
            totalValidatorsFee += validatorsFee[i];
        }

        return (validatorsFee, validatorConfigs, totalValidatorsFee);
    }

    function _validateValidatorLibs(address[] calldata validatorLibs) internal pure {
        // @dev verification that validators are unique
        for (uint256 i; i < validatorLibs.length; ++i) {
            for (uint256 k = i + 1; k < validatorLibs.length; ++k) {
                require(
                    validatorLibs[i] != validatorLibs[k],
                    DuplicateValidatorLib(validatorLibs[i])
                );
            }
        }
    }

    function _retryMessageParamsToDeliverMessageParams(
        RetryMessageSubmissionParams memory retryMessageSubmissionParams,
        bytes32 messageHash,
        bool[] memory validationChecks,
        address receiver,
        uint32 gasLimitOverride
    ) internal pure returns (DeliverMessageParams memory) {
        return
            DeliverMessageParams({
                messageReceipt: retryMessageSubmissionParams.messageReceipt,
                validatorLibs: retryMessageSubmissionParams.validatorLibs,
                validationChecks: validationChecks,
                messageHash: messageHash,
                messageSubmissionHash: getMessageSubmissionHash(
                    retryMessageSubmissionParams.messageReceipt,
                    retryMessageSubmissionParams.relayerLib,
                    retryMessageSubmissionParams.validatorLibs,
                    validationChecks,
                    retryMessageSubmissionParams.validations
                ),
                relayerLib: retryMessageSubmissionParams.relayerLib,
                receiver: receiver,
                gasLimit: gasLimitOverride,
                isRetry: true
            });
    }

    /// @notice Validates that the chain ID has not diverged after deployment.
    /// @dev Reverts if the chain IDs do not match.
    function _whenChainNotForked() internal view {
        if (i_chainID != block.chainid) revert ForkedChain(i_chainID, block.chainid);
    }
}
