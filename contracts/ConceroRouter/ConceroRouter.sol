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
import {MessageCodec} from "../common/libraries/MessageCodec.sol";

contract ConceroRouter is IConceroRouter, IRelayer, Base, ReentrancyGuard {
    using s for s.Router;
    using SafeERC20 for IERC20;
    using MessageCodec for MessageRequest;
    using MessageCodec for bytes;

    error MessageAlreadyProcessed(bytes32 messageHash);
    error MessageSubmissionAlreadyProcessed(bytes32 messageSubmissionHash);
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

        bytes[] memory dstValidatorLibs = new bytes[](messageRequest.validatorLibs.length);
        for (uint256 i; i < dstValidatorLibs.length; ++i) {
            dstValidatorLibs[i] = IValidatorLib(messageRequest.validatorLibs[i]).getDstLib(
                messageRequest.dstChainSelector
            );
        }

        bytes memory packedMessage = messageRequest.toMessageReceiptBytes(
            i_chainSelector,
            msg.sender,
            ++s.router().nonce[msg.sender][i_chainSelector][messageRequest.dstChainSelector],
            IRelayerLib(messageRequest.relayerLib).getDstLib(messageRequest.dstChainSelector),
            dstValidatorLibs
        );

        bytes32 messageId = keccak256(packedMessage);

        emit ConceroMessageSent(messageId, packedMessage);
        emit ConceroMessageFeePaid(messageId, fee);

        return messageId;
    }

    function submitMessage(
        bytes calldata messageReceipt,
        bytes[] calldata validations
    ) external nonReentrant {
        require(
            messageReceipt.dstChainSelector() == i_chainSelector,
            InvalidDstChainSelector(messageReceipt.dstChainSelector(), i_chainSelector)
        );

        require(
            messageReceipt.evmDstValidatorLibs().length == validations.length,
            InvalidValidationsCount(messageReceipt.evmDstValidatorLibs().length, validations.length)
        );

        s.Router storage s_router = s.router();

        bytes32 messageHash = keccak256(messageReceipt);
        require(!s_router.isMessageProcessed[messageHash], MessageAlreadyProcessed(messageHash));

        IRelayerLib(messageReceipt.emvDstRelayerLib()).validate(messageReceipt, msg.sender);

        bool[] memory validationChecks = _performValidationChecks(messageReceipt, validations);

        bytes32 messageSubmissionHash = keccak256(abi.encode(messageReceipt, validationChecks));
        require(
            !s_router.isMessageRetryAllowed[messageSubmissionHash],
            MessageSubmissionAlreadyProcessed(messageSubmissionHash)
        );

        emit ConceroMessageReceived(messageHash, messageReceipt, validations, validationChecks);

        (, uint32 gasLimit) = messageReceipt.evmDstChainData();

        _deliverMessage(
            messageReceipt,
            validationChecks,
            messageHash,
            messageSubmissionHash,
            gasLimit
        );
    }

    function retryMessageSubmission(
        bytes calldata messageReceipt,
        bool[] calldata validationChecks,
        // TODO:mb remove it
        uint32 gasLimitOverride
    ) external nonReentrant {
        s.Router storage s_router = s.router();

        bytes32 messageHash = keccak256(messageReceipt);
        require(!s_router.isMessageProcessed[messageHash], MessageAlreadyProcessed(messageHash));

        bytes32 messageSubmissionHash = keccak256(abi.encode(messageReceipt, validationChecks));
        require(
            s_router.isMessageRetryAllowed[messageSubmissionHash],
            MessageSubmissionAlreadyProcessed(messageSubmissionHash)
        );
		s_router.isMessageRetryAllowed[messageSubmissionHash] = false;

        _deliverMessage(
            messageReceipt,
            validationChecks,
            messageHash,
            messageSubmissionHash,
            gasLimitOverride
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
                revert UnsupportedFeeToken();
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
                revert UnsupportedFeeToken();
            }

            if (balance == 0) continue;

            uint256 conceroFee = balance - s_router.totalRelayerFeeEarned[tokens[i]];

            if (conceroFee == 0) continue;

            Utils.transferNative(msg.sender, conceroFee);

            // TODO: mb add event
        }
    }

    function setConceroMessageFeeInUsd(uint96 amount) external onlyOwner {
        s.router().conceroMessageFeeInUsd = amount;
    }

    function setMaxValidatorsCount(uint16 maxCount) external onlyOwner {
        s.router().maxValidatorsCount = maxCount;
    }

    function setMaxMessageSize(uint64 maxSize) external onlyOwner {
        s.router().maxMessageSize = maxSize;
    }

    function setTokenPriceFeed(address token, address priceFeed) external onlyOwner {
        s.router().priceFeeds[token] = priceFeed;
    }

    /* VIEW FUNCTIONS */

    /* @inheritdoc IConceroRouter */
    function getMessageFee(MessageRequest calldata messageRequest) external view returns (uint256) {
        _validateMessageParams(messageRequest);

        (, uint256 validatorsFee) = _getValidatorsFee(messageRequest);

        return
            getConceroFee(messageRequest.feeToken) +
            IRelayerLib(messageRequest.relayerLib).getFee(messageRequest) +
            validatorsFee;
    }

    function isFeeTokenSupported(address feeToken) public view returns (bool) {
        return feeToken == address(0) || s.router().isFeeTokenSupported[feeToken];
    }

    function getConceroFee(address feeToken) public view returns (uint256) {
        s.Router storage s_router = s.router();

        // e.g. conceroMessageFeeInUsd = 0.1e6 (0.1 USD)
        // getUsdRate(feeToken) = 2000e18 (2000 ETH)
        // $0.1 in ETH = 0.1e6 * 1e12 * 1e18 / 2000e18 = 5e13 ETH
        return
            (uint256(s_router.conceroMessageFeeInUsd) * 1e12 * 1e18) /
            i_conceroPriceFeed.getUsdRate(feeToken);
    }

    function getMaxPayloadSize() public view returns (uint256) {
        return s.router().maxMessageSize;
    }

    function getMaxValidatorsCount() public view returns (uint256) {
        return s.router().maxValidatorsCount;
    }

    /* INTERNAL FUNCTIONS */

    function _deliverMessage(
        bytes calldata messageReceipt,
        bool[] memory validationChecks,
        bytes32 messageHash,
        bytes32 messageSubmissionHash,
        uint32 gasLimit
    ) internal {
        // TODO: handle this error more granular
        (address receiver, ) = messageReceipt.evmDstChainData();

        (bool success, bytes memory result) = Utils.safeCall(
            receiver,
            gasLimit,
            0,
            256,
            abi.encodeWithSelector(
                IConceroClient.conceroReceive.selector,
                messageReceipt,
                validationChecks
            )
        );

        if (success) {
            s.router().isMessageProcessed[messageHash] = true;
            emit ConceroMessageDelivered(messageHash);
        } else {
            if (bytes4(result) == IConceroClient.RelayerNotAllowed.selector) {
                revert IConceroClient.RelayerNotAllowed(messageReceipt.emvDstRelayerLib());
            }

            s.router().isMessageRetryAllowed[messageSubmissionHash] = true;
            emit ConceroMessageDeliveryFailed(messageHash, result);
        }
    }

    function _performValidationChecks(
        bytes calldata messageReceipt,
        bytes[] calldata validations
    ) internal view returns (bool[] memory) {
        bool[] memory validationChecks = new bool[](messageReceipt.evmDstValidatorLibs().length);

        for (uint256 i; i < validationChecks.length; ++i) {
            if (
                //                !Utils.isEvmAddressValid(messageReceipt.evmDstValidatorLibs()[i]) ||
                validations[i].length == 0
            ) {
                validationChecks[i] = false;
            } else {
                bytes memory callData = abi.encodeWithSelector(
                    IValidatorLib.isValid.selector,
                    messageReceipt,
                    validations[i]
                );

                (bool success, bytes memory result) = messageReceipt
                .evmDstValidatorLibs()[i].staticcall(callData);

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
        s.Router storage s_router = s.router();

        require(isFeeTokenSupported(messageRequest.feeToken), UnsupportedFeeToken());
        require(messageRequest.dstChainData.length > 0, EmptyDstChainData());
        require(
            messageRequest.payload.length < s_router.maxMessageSize,
            PayloadTooLarge(messageRequest.payload.length, s_router.maxMessageSize)
        );
        require(
            messageRequest.validatorConfigs.length == messageRequest.validatorLibs.length,
            InvalidValidatorConfigsCount(
                messageRequest.validatorConfigs.length,
                messageRequest.validatorLibs.length
            )
        );
        require(
            messageRequest.validatorLibs.length > 0 &&
                messageRequest.validatorLibs.length < s_router.maxValidatorsCount,
            InvalidValidatorsCount(messageRequest.validatorLibs.length, s_router.maxValidatorsCount)
        );
    }

    function _collectMessageFee(
        MessageRequest calldata messageRequest
    ) internal returns (Fee memory) {
        s.Router storage s_router = s.router();

        uint256 relayerFee = IRelayerLib(messageRequest.relayerLib).getFee(messageRequest);
        (uint256[] memory validatorsFee, uint256 totalValidatorsFee) = _getValidatorsFee(
            messageRequest
        );

        uint256 conceroFee = getConceroFee(messageRequest.feeToken);
        uint256 totalFee = relayerFee + conceroFee + totalValidatorsFee;

        if (messageRequest.feeToken == address(0)) {
            // TODO: mb change to msg.value >= (relayerFee + conceroFee) and send the surplus back to the sender
            require(msg.value == totalFee, CommonErrors.InsufficientFee(msg.value, totalFee));
        } else {
            revert UnsupportedFeeToken();
        }

        uint256 totalRelayerFee = relayerFee + totalValidatorsFee;
        s_router.relayerFeeEarned[messageRequest.relayerLib][
            messageRequest.feeToken
        ] += totalRelayerFee;
        s_router.totalRelayerFeeEarned[messageRequest.feeToken] += totalRelayerFee;

        return
            Fee({
                concero: conceroFee,
                s_relayer: relayerFee,
                validatorsFee: validatorsFee,
                token: messageRequest.feeToken
            });
    }

    function _getValidatorsFee(
        MessageRequest calldata messageRequest
    ) internal view returns (uint256[] memory, uint256) {
        uint256[] memory validatorsFee = new uint256[](messageRequest.validatorLibs.length);
        uint256 totalValidatorsFee;

        for (uint256 i; i < messageRequest.validatorLibs.length; ++i) {
            validatorsFee[i] = IValidatorLib(messageRequest.validatorLibs[i]).getFee(
                messageRequest
            );
            totalValidatorsFee += validatorsFee[i];
        }

        return (validatorsFee, totalValidatorsFee);
    }
}
