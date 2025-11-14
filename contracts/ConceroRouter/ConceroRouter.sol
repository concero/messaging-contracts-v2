// SPDX-License-Identifier: UNLICENSED
/**
 * @title Security Reporting
 * @notice If you discover any security vulnerabilities, please report them responsibly.
 * @contact email: security@concero.io
 */
pragma solidity 0.8.28;

import {Base} from "../common/Base.sol";
import {CommonConstants} from "../common/CommonConstants.sol";
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

contract ConceroRouter is IConceroRouter, IRelayer, Base, ReentrancyGuard {
    using s for s.Router;
    using SafeERC20 for IERC20;
    using MessageCodec for MessageRequest;
    using MessageCodec for bytes;

    error MessageAlreadyProcessed(bytes32 messageHash);
    error MessageSubmissionAlreadyProcessed(bytes32 messageSubmissionHash);
    error InvalidValidationsCount(uint256 validatorLibsCount, uint256 validationsCount);

    event ConceroFeeWithdrawn(address indexed token, uint256 amount);

    uint8 internal constant NATIVE_DECIMALS = 18;

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

        bytes memory packedMessageReceipt = messageRequest.toMessageReceiptBytes(
            i_chainSelector,
            msg.sender,
            ++s.router().nonce[msg.sender][i_chainSelector][messageRequest.dstChainSelector]
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
            !s_router.isMessageRetryAllowed[messageSubmissionHash],
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
        for (uint256 i; i < tokens.length; ++i) {
            uint256 conceroFee = getConceroFeeEarned(tokens[i]);

            if (conceroFee == 0) continue;

            if (tokens[i] == address(0)) {
                Utils.transferNative(msg.sender, conceroFee);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, conceroFee);
            }

            emit ConceroFeeWithdrawn(tokens[i], conceroFee);
        }
    }

    function setConceroMessageFeeInUsd(uint96 amount) external onlyOwner {
        s.router().conceroMessageFeeInUsd = amount;
    }

    function setMaxValidatorsCount(uint16 maxCount) external onlyOwner {
        s.router().maxValidatorsCount = maxCount;
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
        return feeToken == address(0) || s.router().feeTokenConfigs[feeToken].isSupported;
    }

    function getConceroFee(address feeToken) public view returns (uint256) {
        s.Router storage s_router = s.router();

        if (feeToken == address(0)) {
            return ((s_router.conceroMessageFeeInUsd * (10 ** NATIVE_DECIMALS)) /
                i_conceroPriceFeed.getUsdRate(feeToken));
        }

        return
            (Utils.toDecimals(
                s_router.conceroMessageFeeInUsd,
                NATIVE_DECIMALS,
                s_router.feeTokenConfigs[feeToken].decimals
            ) * (10 ** NATIVE_DECIMALS)) / i_conceroPriceFeed.getUsdRate(feeToken);
    }

    function getMaxValidatorsCount() public view returns (uint256) {
        return s.router().maxValidatorsCount;
    }

    function getRelayerFeeEarned(
        address relayerLib,
        address feeToken
    ) public view returns (uint256) {
        return s.router().relayerFeeEarned[relayerLib][feeToken];
    }

    function getConceroFeeEarned(address feeToken) public view returns (uint256) {
        uint256 balance = feeToken == address(0)
            ? address(this).balance
            : IERC20(feeToken).balanceOf(address(this));

        if (balance == 0) return 0;

        return balance - s.router().totalRelayerFeeEarned[feeToken];
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
        try
            IConceroClient(receiver).conceroReceive{gas: gasLimit}(
                messageReceipt,
                validationChecks,
                validatorLibs,
                relayerLib
            )
        {
            s.router().isMessageProcessed[messageHash] = true;
            emit ConceroMessageDelivered(messageHash);
        } catch (bytes memory error) {
            /* @dev This check has been added to prevent malicious relayers
                    from launching spam attacks on the dst chain. */
            if (bytes4(error) == IConceroClient.RelayerNotAllowed.selector) {
                revert IConceroClient.RelayerNotAllowed(relayerLib);
            }

            s.router().isMessageRetryAllowed[messageSubmissionHash] = true;
            emit ConceroMessageDeliveryFailed(messageHash, error);
        }
    }

    function _performValidationChecks(
        bytes calldata messageReceipt,
        bytes[] calldata validations,
        address[] memory dstValidatorLibs
    ) internal view returns (bool[] memory) {
        bool[] memory validationChecks = new bool[](dstValidatorLibs.length);

        for (uint256 i; i < validationChecks.length; ++i) {
            if (validations[i].length == 0) {
                validationChecks[i] = false;
            } else {
                bytes memory callData = abi.encodeWithSelector(
                    IValidatorLib.isValid.selector,
                    messageReceipt,
                    validations[i]
                );

                (bool success, bytes memory result) = dstValidatorLibs[i].staticcall(callData);

                if (success && result.length == 32) {
                    validationChecks[i] = abi.decode(result, (uint256)) == 1;
                } else {
                    validationChecks[i] = false;
                }
            }
        }

        return validationChecks;
    }

    function _validateMessageParams(MessageRequest calldata messageRequest) internal view {
        s.Router storage s_router = s.router();

        require(isFeeTokenSupported(messageRequest.feeToken), UnsupportedFeeToken());
        require(messageRequest.dstChainData.length > 0, EmptyDstChainData());

        require(
            messageRequest.validatorConfigs.length == messageRequest.validatorLibs.length,
            InvalidValidatorConfigsCount(
                messageRequest.validatorConfigs.length,
                messageRequest.validatorLibs.length
            )
        );
        require(
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
        uint256 totalRelayerFee = relayerFee + totalValidatorsFee;
        uint256 totalFee = totalRelayerFee + conceroFee;

        // TODO: mb change to msg.value >= (relayerFee + conceroFee) and send the surplus back to the sender
        require(msg.value >= totalFee, CommonErrors.InsufficientFee(msg.value, totalFee));

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
