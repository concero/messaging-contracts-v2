// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CommonConstants} from "../common/CommonConstants.sol";
import {CommonErrors} from "../common/CommonErrors.sol";
import {Utils} from "../common/libraries/Utils.sol";
import {IConceroClient} from "../interfaces/IConceroClient.sol";
import {IConceroRouter} from "../interfaces/IConceroRouter.sol";
import {IConceroPriceFeed} from "../interfaces/IConceroPriceFeed.sol";
import {IRelayerLib} from "../interfaces/IRelayerLib.sol";
import {IRelayer} from "../interfaces/IRelayer.sol";
import {IValidatorLib} from "../interfaces/IValidatorLib.sol";
import {Storage as s} from "./libraries/Storage.sol";
import {Base} from "./modules/Base.sol";

contract ConceroRouter is IConceroRouter, IRelayer, Base, ReentrancyGuard {
    using s for s.Router;
    using SafeERC20 for IERC20;

    error MessageAlreadyProcessed(bytes32 id, bytes32 messageHash);
    error MessageSubmissionAlreadyProcessed(bytes32 id, bytes32 messageSubmissionHash);
    error InvalidValidationsCount(uint256 validatorLibsCount, uint256 validationsCount);

    constructor(
        uint24 chainSelector,
        address conceroPriceFeed
    ) ReentrancyGuard() Base(chainSelector, conceroPriceFeed) {}

    receive() external payable {}

    /* @inheritdoc IConceroRouter */
    function conceroSend(
        MessageRequest calldata messageRequest
    ) external payable returns (bytes32) {
        _validateMessageParams(messageRequest);
        Fee memory fee = _collectMessageFee(messageRequest);

        bytes32 messageId = _buildMessageId(messageRequest.dstChainSelector);

        MessageReceipt memory messageReceipt = _messageRequestToReceipt(messageRequest);

        emit ConceroMessageSent(messageId, messageReceipt);
        emit ConceroMessageFeePaid(messageId, fee);

        return messageId;
    }

    function submitMessage(
        bytes32 messageId,
        MessageReceipt calldata messageReceipt, // bytes
        bytes[] calldata validations
    ) external nonReentrant {
        require(
            messageReceipt.dstChainSelector == i_chainSelector,
            InvalidDstChainSelector(messageReceipt.dstChainSelector, i_chainSelector)
        );

        require(
            messageReceipt.dstValidatorLibs.length == validations.length,
            InvalidValidationsCount(messageReceipt.dstValidatorLibs.length, validations.length)
        );

        s.Router storage s_router = s.router();

        bytes32 messageHash = keccak256(abi.encode(messageId, messageReceipt));
        require(
            !s_router.isMessageProcessed[messageHash],
            MessageAlreadyProcessed(messageId, messageHash)
        );

        IRelayerLib(abi.decode(messageReceipt.dstRelayerLib, (address))).validate(
            messageId,
            messageReceipt,
            msg.sender
        );

        bool[] memory validationChecks = _performValidationChecks(
            messageId,
            messageReceipt,
            validations
        );

        bytes32 messageSubmissionHash = keccak256(
            abi.encode(messageId, messageReceipt, validationChecks)
        );
        require(
            !s_router.isMessageRetryAllowed[messageSubmissionHash],
            MessageSubmissionAlreadyProcessed(messageId, messageSubmissionHash)
        );

        emit ConceroMessageReceived(messageId, messageReceipt, validations, validationChecks);

        _deliverMessage(
            messageId,
            messageReceipt,
            validationChecks,
            messageHash,
            messageSubmissionHash
        );
    }

    function withdrawRelayerFee(address[] calldata tokens) external nonReentrant {
        s.Router storage s_router = s.router();

        for (uint256 i; i < tokens.length; ++i) {
            uint256 relayerFee = s_router.relayerFeeEarned[msg.sender][tokens[i]];
            s_router.totalRelayerFeeEarned[tokens[i]] -= relayerFee;
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

    /* ADMIN FUNCTIONS */

    function withdrawConceroFee(address[] calldata tokens) external onlyOwner {
        s.Router storage s_router = s.router();

        for (uint256 i; i < tokens.length; ++i) {
            uint256 balance;

            if (tokens[i] == address(0)) {
                balance = address(this).balance;
            } else {
                balance = IERC20(tokens[i]).balanceOf(address(this));
            }

            if (balance == 0) continue;

            uint256 conceroFee = balance - s_router.totalRelayerFeeEarned[tokens[i]];

            if (conceroFee == 0) continue;

            if (tokens[i] == address(0)) {
                Utils.transferNative(msg.sender, conceroFee);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, conceroFee);
            }

            // TODO: mb add event
        }
    }

    function setConceroMessageFeeInUsd(uint96 amount) external onlyOwner {
        s.router().conceroMessageFeeInUsd = amount;
    }

    /* VIEW FUNCTIONS */

    /* @inheritdoc IConceroRouter */
    function getMessageFee(MessageRequest calldata messageRequest) external view returns (uint256) {
        _validateMessageParams(messageRequest);

        return
            getConceroFee(messageRequest.feeToken) +
            IRelayerLib(messageRequest.relayerLib).getFee(messageRequest);
    }

    function isFeeTokenSupported(address feeToken) public view returns (bool) {
        return feeToken == address(0) || s.router().isFeeTokenSupported[feeToken];
    }

    function getConceroFee(address feeToken) public view returns (uint256) {
        s.Router storage s_router = s.router();

        return
            IConceroPriceFeed(s_router.priceFeeds[feeToken]).getUsdRate(feeToken) *
            s_router.conceroMessageFeeInUsd;
    }

    /* INTERNAL FUNCTIONS */

    function _deliverMessage(
        bytes32 messageId,
        MessageReceipt calldata messageReceipt,
        bool[] memory validationChecks,
        bytes32 messageHash,
        bytes32 messageSubmissionHash
    ) internal {
        // TODO: handle this error more granular
        EvmDstChainData memory dstChainData = abi.decode(
            messageReceipt.dstChainData,
            (EvmDstChainData)
        );

        (bool success, bytes memory result) = Utils.safeCall(
            dstChainData.receiver,
            dstChainData.gasLimit,
            0,
            256,
            abi.encodeWithSelector(
                IConceroClient.conceroReceive.selector,
                messageId,
                messageReceipt,
                validationChecks
            )
        );

        if (success) {
            s.router().isMessageProcessed[messageHash] = true;
            emit ConceroMessageDelivered(messageId);
        } else {
            // TODO: add check if invalid relayer - revert
            s.router().isMessageRetryAllowed[messageSubmissionHash] = true;
            emit ConceroMessageDeliveryFailed(messageId, result);
        }
    }

    function _performValidationChecks(
        bytes32 messageId,
        MessageReceipt calldata messageReceipt,
        bytes[] calldata validations
    ) internal view returns (bool[] memory) {
        bool[] memory validationChecks = new bool[](messageReceipt.dstValidatorLibs.length);

        for (uint256 i; i < messageReceipt.dstValidatorLibs.length; ++i) {
            if (
                !Utils.isEvmAddressValid(messageReceipt.dstValidatorLibs[i]) ||
                validations[i].length == 0
            ) {
                validationChecks[i] = false;
            } else {
                bytes memory callData = abi.encodeWithSelector(
                    IValidatorLib.isValid.selector,
                    messageId,
                    messageReceipt,
                    validations[i]
                );

                (bool success, bytes memory result) = abi
                    .decode(messageReceipt.dstValidatorLibs[i], (address))
                    .staticcall(callData);

                if (success && result.length == 32) {
                    validationChecks[i] = abi.decode(result, (uint256)) == 1;
                } else {
                    validationChecks[i] = false;
                }
            }
        }

        return validationChecks;
    }

    function _validateMessageParams(MessageRequest memory messageRequest) internal view {
        // TODO: add check validator libs count checks
        require(isFeeTokenSupported(messageRequest.feeToken), UnsupportedFeeToken());
        require(messageRequest.dstChainData.length > 0, EmptyDstChainData());
        require(
            messageRequest.payload.length < CommonConstants.MESSAGE_MAX_SIZE,
            MessageTooLarge(messageRequest.payload.length, CommonConstants.MESSAGE_MAX_SIZE)
        );
        require(
            messageRequest.validatorLibs.length > 0 &&
                messageRequest.validatorLibs.length < s.router().maxValidatorsCount,
            InvalidValidatorsCount(
                messageRequest.validatorLibs.length,
                s.router().maxValidatorsCount
            )
        );
    }

    function _buildMessageId(uint24 dstChainSelector) private returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ++s.router().nonce,
                    block.number,
                    msg.sender,
                    i_chainSelector,
                    dstChainSelector
                )
            );
    }

    function _collectMessageFee(
        MessageRequest calldata messageRequest
    ) internal returns (Fee memory) {
        s.Router storage s_router = s.router();

        uint256 relayerFee = IRelayerLib(messageRequest.relayerLib).getFee(messageRequest);
        uint256 totalValidatorsFee;
        uint256[] memory validatorsFee = new uint256[](messageRequest.validatorLibs.length);

        for (uint256 i; i < messageRequest.validatorLibs.length; ++i) {
            validatorsFee[i] = IValidatorLib(messageRequest.validatorLibs[i]).getFee(
                messageRequest
            );
            totalValidatorsFee += validatorsFee[i];
        }

        uint256 conceroFee = getConceroFee(messageRequest.feeToken);
        uint256 totalFee = relayerFee + conceroFee + totalValidatorsFee;

        if (messageRequest.feeToken == address(0)) {
            // TODO: mb change to msg.value >= (relayerFee + conceroFee) and send the surplus back to the sender
            require(msg.value == totalFee, CommonErrors.InsufficientFee(msg.value, totalFee));
        } else {
            IERC20(messageRequest.feeToken).safeTransferFrom(msg.sender, address(this), totalFee);
        }

        uint256 totalRelayerFee = relayerFee + totalValidatorsFee;
        s_router.relayerFeeEarned[messageRequest.relayerLib][
            messageRequest.feeToken
        ] += totalRelayerFee;
        s_router.totalRelayerFeeEarned[messageRequest.feeToken] += totalRelayerFee;

        return
            Fee({
                concero: conceroFee,
                relayer: relayerFee,
                validatorsFee: validatorsFee,
                token: messageRequest.feeToken
            });
    }

    function _messageRequestToReceipt(
        MessageRequest calldata messageRequest
    ) internal view returns (MessageReceipt memory) {
        bytes[] memory dstValidatorLibs = new bytes[](messageRequest.validatorLibs.length);

        for (uint256 i; i < dstValidatorLibs.length; ++i) {
            dstValidatorLibs[i] = IValidatorLib(messageRequest.validatorLibs[i]).getDstLib(
                messageRequest.dstChainSelector
            );
        }

        return
            MessageReceipt({
                srcChainSelector: i_chainSelector,
                dstChainSelector: messageRequest.dstChainSelector,
                srcChainData: abi.encode(
                    EvmSrcChainData({
                        blockConfirmations: messageRequest.srcBlockConfirmations,
                        sender: msg.sender
                    })
                ),
                dstChainData: messageRequest.dstChainData,
                dstRelayerLib: IRelayerLib(messageRequest.relayerLib).getDstLib(
                    messageRequest.dstChainSelector
                ),
                dstValidatorLibs: dstValidatorLibs,
                validatorConfigs: messageRequest.validatorConfigs,
                relayerConfig: messageRequest.relayerConfig,
                validationRpcs: messageRequest.validationRpcs,
                deliveryRpcs: messageRequest.deliveryRpcs,
                payload: messageRequest.payload
            });
    }
}
