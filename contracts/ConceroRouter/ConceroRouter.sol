// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {CommonErrors} from "../common/CommonErrors.sol";
import {IConceroClient} from "../interfaces/IConceroClient.sol";
import {IConceroPriceFeed} from "../interfaces/IConceroPriceFeed.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRelayerLib} from "../interfaces/IRelayerLib.sol";
import {IRelayer} from "../interfaces/IRelayer.sol";
import {IValidatorLib} from "../interfaces/IValidatorLib.sol";
import {MessageCodec} from "../common/libraries/MessageCodec.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Storage as s} from "./libraries/Storage.sol";
import {Utils} from "../common/libraries/Utils.sol";
import {ValidatorCodec} from "../common/libraries/ValidatorCodec.sol";

contract ConceroRouter is IConceroRouter, IRelayer, ReentrancyGuard {
    using s for s.Router;
    using SafeERC20 for IERC20;
    using MessageCodec for MessageRequest;
    using MessageCodec for bytes;
    using ValidatorCodec for bytes;

    uint8 internal constant NATIVE_DECIMALS = 18;

    uint24 internal immutable i_chainSelector;

    constructor(uint24 chainSelector) ReentrancyGuard() {
        i_chainSelector = chainSelector;
    }

    receive() external payable {}

    /* @inheritdoc IConceroRouter */
    function conceroSend(
        MessageRequest calldata messageRequest
    ) external payable returns (bytes32) {
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

    function submitMessage(
        bytes calldata messageReceipt,
        bytes[] calldata validations,
        address[] calldata validatorLibs,
        address relayerLib
    ) external nonReentrant {
        require(
            messageReceipt.dstChainSelector() == i_chainSelector,
            InvalidDstChainSelector(messageReceipt.dstChainSelector(), i_chainSelector)
        );
        require(
            validatorLibs.length == validations.length,
            InvalidValidationsCount(validatorLibs.length, validations.length)
        );

        s.Router storage s_router = s.router();

        bytes32 messageHash = keccak256(messageReceipt);
        require(!s_router.isMessageProcessed[messageHash], MessageAlreadyProcessed(messageHash));

        IRelayerLib(relayerLib).validate(messageReceipt, msg.sender);

        bool[] memory validationChecks = _performValidationChecks(
            messageReceipt,
            validations,
            validatorLibs
        );

        bytes32 messageSubmissionHash = keccak256(abi.encode(messageReceipt, validationChecks));
        require(
            !s_router.isMessageRetryable[messageSubmissionHash],
            MessageSubmissionAlreadyProcessed(messageSubmissionHash)
        );

        emit ConceroMessageReceived(
            messageHash,
            messageReceipt,
            validations,
            validatorLibs,
            validationChecks,
            relayerLib
        );

        (address receiver, uint32 gasLimit) = messageReceipt.evmDstChainData();

        _deliverMessage(
            messageReceipt,
            validatorLibs,
            validationChecks,
            messageHash,
            messageSubmissionHash,
            receiver,
            relayerLib,
            gasLimit
        );
    }

    function retryMessageSubmission(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        address[] calldata validatorLibs,
        address relayerLib,
        uint32 gasLimitOverride
    ) external nonReentrant {
        s.Router storage s_router = s.router();

        bytes32 messageHash = keccak256(messageReceipt);
        require(!s_router.isMessageProcessed[messageHash], MessageAlreadyProcessed(messageHash));

        bytes32 messageSubmissionHash = keccak256(abi.encode(messageReceipt, validationChecks));
        require(
            s_router.isMessageRetryable[messageSubmissionHash],
            MessageSubmissionAlreadyProcessed(messageSubmissionHash)
        );
        s_router.isMessageRetryable[messageSubmissionHash] = false;

        (address receiver, ) = messageReceipt.evmDstChainData();

        _deliverMessage(
            messageReceipt,
            validatorLibs,
            validationChecks,
            messageHash,
            messageSubmissionHash,
            receiver,
            relayerLib,
            gasLimitOverride
        );
    }

    function withdrawRelayerFee(address[] calldata tokens) external nonReentrant {
        s.Router storage s_router = s.router();

        for (uint256 i; i < tokens.length; ++i) {
            uint256 relayerFee = s_router.relayerFeeEarned[msg.sender][tokens[i]];
            s_router.relayerFeeEarned[msg.sender][tokens[i]] = 0;

            if (relayerFee == 0) continue;

            if (tokens[i] == address(0)) {
                Utils.transferNative(msg.sender, relayerFee);
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

        (, bytes[] memory operatorConfigs, uint256 validatorsFee) = _getValidatorsFeeAndConfigs(
            messageRequest
        );

        return
            IRelayerLib(messageRequest.relayerLib).getFee(messageRequest, operatorConfigs) +
            validatorsFee;
    }

    function getRelayerFeeEarned(
        address relayerLib,
        address feeToken
    ) public view returns (uint256) {
        return s.router().relayerFeeEarned[relayerLib][feeToken];
    }

    function isMessageProcessed(bytes32 messageId) public view returns (bool) {
        return s.router().isMessageProcessed[messageId];
    }

    function isMessageRetryable(bytes32 messageId) public view returns (bool) {
        return s.router().isMessageRetryable[messageId];
    }

    /* INTERNAL FUNCTIONS */

    function _deliverMessage(
        bytes calldata messageReceipt,
        address[] calldata validatorLibs,
        bool[] memory validationChecks,
        bytes32 messageHash,
        bytes32 messageSubmissionHash,
        address receiver,
        address relayerLib,
        uint32 gasLimit
    ) internal {
        bytes memory callData = abi.encodeWithSelector(
            IConceroClient.conceroReceive.selector,
            messageReceipt,
            validationChecks,
            validatorLibs,
            relayerLib
        );

        (bool success, bytes memory res) = receiver.call{gas: gasLimit}(callData);

        if (success) {
            s.router().isMessageProcessed[messageHash] = true;
            emit ConceroMessageDelivered(messageHash);
        } else {
            s.router().isMessageRetryable[messageSubmissionHash] = true;
            emit ConceroMessageDeliveryFailed(messageHash, res);
        }
    }

    function _performValidationChecks(
        bytes calldata messageReceipt,
        bytes[] calldata validations,
        address[] memory dstValidatorLibs
    ) internal view returns (bool[] memory) {
        bool[] memory validationChecks = new bool[](dstValidatorLibs.length);
        bytes[] memory internalValidatorConfigs = messageReceipt.internalValidatorsConfig();

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

                (bool success, bytes memory result) = dstValidatorLibs[i].staticcall{
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
            require(
                msg.value == totalRelayerFee,
                CommonErrors.InsufficientFee(msg.value, totalRelayerFee)
            );
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
}
